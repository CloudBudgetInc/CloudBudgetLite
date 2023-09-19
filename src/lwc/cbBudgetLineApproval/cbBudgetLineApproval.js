import {api, LightningElement, track} from "lwc";
import getBudgetLinesForApproveServer from "@salesforce/apex/CBApprovalPageController.getBudgetLinesForApproveServer";
import getUserServer from "@salesforce/apex/CBApprovalPageController.getUserServer";
import sendEmailToController from "@salesforce/apex/CBApprovalPageController.sendEmailToController";
import triggerStatusServer from "@salesforce/apex/CBApprovalPageController.triggerStatusServer";
import saveBLtoServer from "@salesforce/apex/CBApprovalPageController.saveBLtoServer";
import checkIfUserNotAdminServer from "@salesforce/apex/CBApprovalPageController.checkIfUserNotAdminServer";
import {
	_applyDecStyle,
	_cl,
	_generateFakeId,
	_getCopy,
	_message,
	_parseServerError,
} from "c/cbUtils";

export default class CbBudgetLineApproval extends LightningElement {
	@api showSpinner = false;
	@api budgetLineIds = []; // list of selected budget line ids

	@track budgetLineGroups = []; // render children clusters if needed
	@track showModal = false;
	@track emailRecieverIdList = [];
	@track emailText;
	@track emailTopic;
	@track deadline;
	@track userIsNotAdmin = false;
	@track budgetLines = [];
	@track mailingBudgetLines = [];
	@track deadlineNotChecked = true;

	activeApprovalSections = [];

	userList = [];
	keys = [
		"OwnerId",
		"cblight__APHaveAccessToBack__c",
		"cblight__APHaveAccessToAhead__c",
	];

	async connectedCallback() {
		await this.getListOfBudgetLines();
		this.setNotAdminView();
		await this.getUserListSO();
		let currentDate = new Date().toJSON().slice(0, 10);
		this.deadline = currentDate.toString();
		this.setInitAccordionActiveSections();
	}

	/**
	 * This method checks if user admin or not and set view mode
	 */

	setNotAdminView() {
		checkIfUserNotAdminServer().then(userIsNotAdmin => {
			this.userIsNotAdmin = userIsNotAdmin;
		});
	}

	/**
	 * This method gets a list of selected budget lines with needed fields to change them a status
	 */
	async getListOfBudgetLines() {
		this.showSpinner = true;
		await getBudgetLinesForApproveServer({budgetLineIds: this.budgetLineIds})
			.then(budgetLines => {
				try {
					this.budgetLineGroups = this.generateBudgetLineGroups(budgetLines);
				} catch (e) {
					_parseServerError("Get List Of Budget Lines Callback Error: ", e);
				}
			})
			.catch(e => _message("error", "Get Budget Lines Error: " + e));
	}

	setInitAccordionActiveSections() {
		this.activeApprovalSections.push(this.budgetLineGroups[0].title);
	}

	/**
	 * The method returns BL User SO for BL
	 */
	getUserListSO() {
		try {
			getUserServer()
				.then(userListfromServer => {
					userListfromServer.forEach(line => {
						this.userList.push({
							label: line.Name,
							value: line.Id,
						});
					});
				})
				.catch(e => _parseServerError("Get User Select Options from Server Error", e))
				.finally(() => this.showSpinner = false);
		} catch (e) {
			_message("error", `Approval Manager : Get List Of User Error ${e}`);
		}
	}

	/**
	 * This method changes statuses for a bunch of budget lines (Back and Forward)
	 */
	triggerStatus(event) {
		const status = event.target.value;
		const isForward = event.target.name === "forward";
		const BLG = this.budgetLineGroups.find(blg => blg.status === status);
		const budgetLineIds = BLG.value; // selected list of Ids
		this.showSpinner = true;
		triggerStatusServer({budgetLineIds, isForward})
			.then(() => {
				this.getListOfBudgetLines();
				_message("success", "Status changed");
				this.closeApprovalWindow();

			})
			.catch(e => _parseServerError("Change status Server Error: ", e))
			.finally(() => this.showSpinner = false)
	}

	/**
	 * This method handle User changes
	 */
	handleUsers(event) {
		let userId = event.target.value;
		let lineField = event.target.name;
		let lineId = event.target.dataset.id;

		this.budgetLines.find(line => {
			if (line.Id == lineId) {
				line[lineField] = userId;
			}
		});
		if (this.budgetLines.filter(line => line.Id === lineId).length == 0)
			this.budgetLines.push({Id: lineId, [lineField]: userId});
	}

	/**
	 * This method saves user changes
	 */
	changeBLUsers() {
		try {
			const budgetLines = this.budgetLines;
			if (budgetLines.length == 0) {
				_message("error", "Change at least one user");
				return;
			}
			this.showSpinner = true;
			saveBLtoServer({budgetLines: budgetLines})
				.then(() => {
					this.getListOfBudgetLines();
					_message("success", "Users are changed");
					this.budgetLines = [];
				})
				.catch(e => {
					_parseServerError("BL updates server error ", e);
				})
				.finally(() => this.showSpinner = false)
		} catch (e) {
			_message("error", "BL save to server error " + JSON.stringify(e));
		}
	}

	/**
	 * handler for selecting needed budget lines in the list
	 */
	handleBLList(event) {
		let status = event.target.name;
		let lineId = event.target.value;
		let checked = event.target.checked;
		let BLG = this.budgetLineGroups.find(blg => blg.status === status);
		let index = this.budgetLineGroups.indexOf(BLG);
		let value = this.budgetLineGroups[index].value;
		if (checked) value.push(lineId);
		if (!checked) value = value.filter(Id => Id !== lineId);
		this.budgetLineGroups[index].value = value;
	}

	/**
	 * open Email Modal
	 */
	openEmailModal(event) {
		this.mailingBudgetLines = [];
		this.emailRecieverIdList = [];

		let eventId = event.target.dataset.id;
		let lineId = event.target.value;
		let status = event.target.name;

		const BLG = this.budgetLineGroups.find(blg => blg.status === status);
		const lineList = BLG.lines;

		switch (eventId) {
			case "oneLineMailing":
				const line = lineList.find(line => line.Id == lineId);
				this.mailingBudgetLines.push(line);
				this.emailText =
					"Please, approove/submit BL:" + this.mailingBudgetLines[0].Name;
				this.emailTopic =
					"Approval Process Notification for BL: " +
					this.mailingBudgetLines[0].Name;
				break;
			case "groupMailing" :
				let lines = BLG.lines;
				let value = BLG.value;
				this.mailingBudgetLines = lines.filter(line => value.includes(line.Id));
				this.emailText =
					"Please, approove/submit BL list in status: " + BLG.status;
				this.emailTopic = "Approval Process Notification for BL list.";
				break;
		}
		this.keys.forEach(key => {
			this.mailingBudgetLines.forEach(line => {
				if (!this.emailRecieverIdList.includes(line[key])) {
					this.emailRecieverIdList.push(line[key]);
				}
			});
		});
		this.showModal = true;
	}

	/**
	 * This method handles text or topic input
	 */
	handleInputChange(event) {
		let value = event.target.value;
		let name = event.target.name;
		this[name] = value;
	}

	/**
	 * This method added deadline to message
	 */
	addDeadlineToMail() {
		this.deadlineNotChecked = !this.deadlineNotChecked;
	}

	/**
	 * This method adds or remove userid to mail reciever
	 */
	addUserToNotification(event) {
		let userId = event.target.value;
		let checked = event.target.checked;
		let targetId = event.currentTarget.dataset.id;

		if (checked) {
			if (!this.emailRecieverIdList.includes(userId)) {
				this.emailRecieverIdList.push(userId);
			}
			this.template
				.querySelectorAll(`[data-id="${targetId}"]`)
				.forEach(checkbox => (checkbox.checked = true));
		}
		if (!checked) {
			if (this.emailRecieverIdList.length == 1) {
				_message(
					"error",
					"You removed all users from reciever list, please add at least one"
				);
			}
			this.emailRecieverIdList = this.emailRecieverIdList.filter(
				Id => Id != userId
			);
			this.template
				.querySelectorAll(`[data-id="${targetId}"]`)
				.forEach(checkbox => (checkbox.checked = false));
		}
	}

	/**
	 * This method sends email notification to Users
	 */
	sendNotificationtoSpecifiedUser() {
		try {
			if (this.emailRecieverIdList.length === 0) {
				_message("error", "Add at least one User");
				return;
			}
			if (!this.deadlineNotChecked)
				this.emailText = this.emailText + ". Final Date is: " + this.deadline;
			sendEmailToController({
				body: this.emailText,
				userIdList: this.emailRecieverIdList,
				subject: this.emailTopic,
			})
				.then(() => {
					_message(
						"success",
						"An email has been sent to " +
						this.emailRecieverIdList.length +
						" user(s)"
					);
					this.toggleModal();
				})
				.catch(e => {
					_parseServerError("Email notification send from server error ", e);
				});
		} catch (e) {
			_message("error", "Email notification error " + e);
		}
	}

	/**
	 * This method toggle Modal
	 */
	toggleModal() {
		this.showModal = !this.showModal;
		if (!this.showModal) this.emailRecieverIdList = [];
	}

	/**
	 * The method closes Approval component and reloads the budget line page
	 * It sends an event to the Budget Manager component
	 */
	closeApprovalWindow() {
		this.dispatchEvent(
			new CustomEvent("closeStatusWindow", {
				bubbles: true,
				composed: true,
			})
		);
	}

	/**
	 * Service method may be moved to extra lib
	 * returns budget lines grouped by status
	 * @param budgetLines is list of selected budget lines received form server
	 */
	generateBudgetLineGroups(budgetLines) {
		const BLGroupMap = {};
		budgetLines.forEach(line => {
			let BLG = BLGroupMap[line.cblight__Status__c];
			if (!BLG) {
				BLG = new BLGroup();
				BLG.status = line.cblight__Status__c;
				BLG.nextStatus = line.cblight__APNextStatusName__c;
				BLG.previousStatus = line.cblight__APPreviousStatusName__c;
				BLG.title = line.cblight__Status__c + " Budget Lines";
				BLG.nextStatus = line.cblight__APNextStatusName__c;
				BLG.previousStatus = line.cblight__APPreviousStatusName__c;
				BLGroupMap[line.cblight__Status__c] = BLG;
			}
			BLG.lines.push({
				Name: line.Name,
				Amount: line.cblight__Value__c,
				Id: line.Id,
				OwnerId: line.OwnerId,
				OwnerName: line.Owner.Name,
				cblight__APNextStatusName__c: line.cblight__APNextStatusName__c,
				cblight__APPreviousStatusName__c: line.cblight__APPreviousStatusName__c,
				cblight__ParentBudgetLine__c: line.cblight__ParentBudgetLine__c,
				cblight__Status__c: line.cblight__Status__c,
				cblight__APHaveAccessToAhead__c: line.cblight__APHaveAccessToAhead__c,
				APHaveAccessToAheadName: line.cblight__APHaveAccessToAhead__c
					? line.cblight__APHaveAccessToAhead__r.Name
					: "",
				cblight__APHaveAccessToBack__c: line.cblight__APHaveAccessToBack__c,
				APHaveAccessToBackName: line.cblight__APHaveAccessToBack__c
					? line.cblight__APHaveAccessToBack__r.Name
					: "",
			});
			BLG.value.push(line.Id);
		});
		return Object.values(BLGroupMap);
	}
}

/**
 * Service class to store group of budget lines with the common status
 */
function BLGroup() {
	this.lines = [];
	this.status;
	this.nextStatus;
	this.previousStatus;
	this.title;
	this.value = [];
	this.nextStatus = "";
	this.previousStatus = "";
}