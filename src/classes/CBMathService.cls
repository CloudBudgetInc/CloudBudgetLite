/** 
Copyright (c) 2022, CloudBudget, Inc.
All rights reserved.
Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:
* Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.
* Neither the name of the CloudBudget, Inc. nor the names of its contributors
may be used to endorse or promote products derived from this software
without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
OF THE POSSIBILITY OF SUCH DAMAGE.

Special class to calculate amounts and formulas
 */

public with sharing class CBMathService {

	/**
     * Reverse Polish notation (RPN) calculates mathematical equation
     *
     * @param equation '(9 + 21) * 86 / (2 + 4) '
     *
     * @return 430.00
     */
	public static Decimal calculateEquation(String equation) {
		try {
			if (String.isEmpty(equation)) return 0;
			equation = equation.trim().deleteWhitespace();
			List<String> buffer = prepareBuffer(equation);
			List<String> outList = prepareReversePolishNotation(buffer);
			return calculateResult(outList);
		} catch (Exception e) {
			return -1;
		}
	}

	/**
	 * Converts an equation to array of members
	 *
	 * @param equation string with equation '(9 + 21) * 86 / (2 + 4) '
	 *
	 * @return ((, 9, +, 21, ), *, 86, /, (, 2, ...)
	 */
	@TestVisible
	private static List<String> prepareBuffer(String equation) {
		List<String> buffer = new List<String>(50);
		Integer index = 0, lim;
		Boolean minusFlag = false;
		String symbol;

		for (Integer i = 0; i < equation.length(); i++) {
			lim = i + 1;
			symbol = equation.substring(i, lim);
			if (i == 0 && symbol.equals('-')) {
				minusFlag = true;
				continue;
			}
			if (isNumber(symbol) || symbol.equals('.')) {
				buffer[index] = buffer[index] == null ? symbol : buffer[index] + symbol;
			} else {
				if (minusFlag && buffer[index] != null) {
					buffer[index] = '-' + buffer[index]; // если флаг минуса сработал и в buffer[index] лежит какое-то число. Сделать его отрицательным
				}
				if (buffer[index] != null) {
					index++;
				}
				buffer[index] = symbol;
				index++;
			}
		}
		return trimToSize(buffer);
	}

	/**
	 * Method converts buffer to reverse Polish notation ready for calculating
	 *
	 * @param buffer ((, 9, +, 21, ), *, 86, /, (, 2, ...)
	 *
	 * @return (9, 21, +, 86, *, 2, 4, +, /)
	 */
	@TestVisible
	private static List<String> prepareReversePolishNotation(List<String> buffer) {
		List<String> outList = new List<String>();
		List<String> signStack = new List<String>();
		Integer count;

		for (Integer i = 0; i < buffer.size(); i++) {
			if (String.isEmpty(buffer[i])) continue;
			if (isNumber(buffer[i])) {
				outList.add(buffer[i]);
			} else {
				if (buffer[i].equals(')')) {
					count = signStack.size() - 1;
					while (!signStack[count].equals('(')) {
						outList.add(signStack.remove(count));
						count--;
					}
					signStack.remove(count);
					continue;
				} else if (signStack.size() > 0 && !buffer[i].equals('(') && getPriority(signStack[signStack.size() - 1]) >= getPriority(buffer[i])) {
					outList.add(signStack.remove(signStack.size() - 1)); // вытеснить знак из стека в выводную строку
				}
				signStack.add(buffer[i]); // знак ложится в стек
			}
		}
		signStack = reverseList(signStack);
		outList.addAll(signStack);
		return trimToSize(outList);
	}

	/**
	 * Method calculates result
	 *
	 * @param outList (9, 21, +, 86, *, 2, 4, +, /)
	 *
	 * @return 430.00
	 */
	@TestVisible
	private static Decimal calculateResult(List<String> outList) {
		String arg1, arg2, sign;
		for (Integer i = 0; i < outList.size(); i++) {
			if (isNumber(outList[i])) {
				if (arg1 == null) {
					arg1 = outList[i];
					continue;
				}
				if (arg2 == null) {
					arg2 = outList[i];
					continue;
				}
				arg1 = arg2;
				arg2 = outList[i];
			} else {
				outList[i] = countEquation(arg1, arg2, outList[i]);
				arg1 = arg2 = null;
				outList[i - 1] = outList[i - 2] = null;
				outList = trimToSize(outList);
				i = -1;
			}
		}
		arg1 = arg2 = sign = null;
		return Decimal.valueOf(outList[0]);
	}


	/**
	 * Method deletes null values from the list of Strings
	 *
	 * @param inp source list
	 * @return updated list
	 */
	@TestVisible
	private static List<String> trimToSize(List<String> inp) {
		List<String> out = new List<String>();
		for (String s : inp) {
			if (String.isEmpty(s)) continue;
			out.add(s);
		}
		return out;
	}


	static final Pattern DECIMAL_PATTERN = Pattern.compile('^[-+]?\\d+(\\.\\d*)?$');
	/**
	 * @param symbol some string for checking
	 *
	 * @return true if string contains decimal
	 */
	@TestVisible
	private static Boolean isNumber(String symbol) {
		return DECIMAL_PATTERN.matcher(symbol).find();
	}

	/**
     * Different relations has different priority for Reverse Polish notation (RPN)
     * @param s is sign
     * @return priority form -1 to 2
     */
	@TestVisible
	private static Integer getPriority(String s) {
		switch on s {
			when '', null {
				return -1;
			}
			when '(' {
				return 0;
			}
			when ')' {
				return 1;
			}
			when '-', '+' {
				return 2;
			}
			when '*', '/' {
				return 3;
			}
			when else {
				return -1;
			}
		}
	}

	/**
	 * The method reverses array of string
	 *
	 * @param input input array
	 *
	 * @return reversed array
	 */
	@TestVisible
	private static List<String> reverseList(List<String> input) {
		List<String> output = new List<String>();
		if (input.isEmpty()) return output;
		for (Integer i = input.size() - 1; i >= 0; i--) {
			if (String.isEmpty(input[i])) continue;
			output.add(input[i]);
		}
		return output;
	}

	/**
	 * Calculates relation between arguments
	 *
	 * @param a first argument
	 * @param b second argument
	 * @param sign between them
	 *
	 * @return result of calculation
	 */
	@TestVisible
	private static String countEquation(String a, String b, String sign) {
		try {
			switch on sign {
				when '+' {
					return String.valueOf((Decimal.valueOf(a) + Decimal.valueOf(b)).setscale(2));
				}
				when '-' {
					return String.valueOf((Decimal.valueOf(a) - Decimal.valueOf(b)).setscale(2));
				}
				when '*' {
					return String.valueOf((Decimal.valueOf(a) * Decimal.valueOf(b)).setscale(2));
				}
				when '/' {
					return String.valueOf((Decimal.valueOf(a) / Decimal.valueOf(b)).setscale(2));
				}
				when else {
					return '0';
				}
			}
		} catch (Exception e) {
			throw new CBMathException('Count Equation Error: ' + e);
		}
	}

	class CBMathException extends Exception {

	}


}