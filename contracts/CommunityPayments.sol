//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Errors} from './library/Errors.sol';

import 'hardhat/console.sol';

/**
 * @title Community Payments
 * @author Tomas Rawski
 *
 * @notice This is the main entrypoint of the Community Payments.
 */
contract CommunityPayments {
	struct CommunityPayment {
		uint256 communityId;
		uint256 amountTotal;
		uint256 amountPaid;
		uint256 paymentsLength;
		address creator;
		bool isActive;
		bool isRevert;
		bool isTransfered;
	}

	struct PaymentInfo {
		address sender;
		uint256 amount;
	}

	struct CommunityPaymentReturn {
		uint256 communityId;
		uint256 amountTotal;
		uint256 amountPaid;
		uint256 paymentsLength;
		address creator;
	}

	struct Community {
		string name;
		address receiverAddress;
		address communityOwner;
		uint256 lastCommunityPayment;
	}

	// Mapping of all created community payments by CommunityId
	mapping(uint => CommunityPayment) communityPayments;

	// Mapping of all detailed community payments by CommunityPaymentId
	mapping(uint => PaymentInfo[]) communityPaymentsDetail;

	// Array to store information about all communities
	Community[] public communities;

	// Counter to track the last created community
	uint256 public lastCommunity = 0;

	// Variable to store the payment revert fee (in basis points)
	uint256 public paymentRevertFee = 10; // 0.1% = 10 basis points

	// Variable to track the aggregated total of all community payment amounts
	uint256 public amountTotalAggregated = 0;

	// Address of the contract owner
	address private owner;

	// Events to log important contract actions
	event CommunityCreate(uint256 idCommunity, string name, address receiver, address emiter);
	event CommunityPaymentSent(
		uint256 idCommunity,
		uint256 idCommunityPayment,
		uint256 amountPaid,
		address emiter
	);
	event CommunityPaymentCreate(
		uint256 idCommunity,
		uint256 idCommunityPayment,
		address emiter,
		uint256 amount
	);
	event CommunityPaymentTotal(
		uint256 idCommunity,
		uint256 idCommunityPayment,
		uint256 amountTotal,
		address receiver,
		address emiter
	);
	event WithdrawFees(uint256 total, address receiver);
	event RevertComunityPayments(uint256 idCommunityPayment);
	event RevertIndividualCommunityPayment(
		uint256 idCommunityPayment,
		address revertReceiver,
		uint256 returnAmount,
		uint256 paymentRevertPorcent
	);

	/**
	 * @dev The constructor sets the owner.
	 */
	constructor() {
		owner = msg.sender;
	}

	/**
	 * @dev Create a Community and return the id
	 * @param _name The name of the community
	 * @param _receive The address of the receiver
	 * @return id The id of the community
	 */
	function createCommunity(string memory _name, address _receive) public returns (uint256 id) {
		communities.push(Community(_name, _receive, msg.sender, 0));

		id = lastCommunity;
		lastCommunity++;

		emit CommunityCreate(id, _name, _receive, msg.sender);
	}

	/**
	 * @dev Create a Community Payment and return de id
	 * @param _communityId The id of the community
	 * @param _total The total amount of the payment
	 * @return id The id of the community payment
	 * Only the community owner can create one
	 **/
	function createCommunityPayment(
		uint256 _communityId,
		uint256 _total
	) public onlyCommunityOwner(_communityId) returns (uint256 id) {
		if (_total <= 0) revert Errors.AmountIsZero();
		Community memory c = communities[_communityId];

		communityPayments[c.lastCommunityPayment] = CommunityPayment(
			_communityId,
			_total,
			0,
			0,
			msg.sender,
			true,
			false,
			false
		);

		id = c.lastCommunityPayment;
		c.lastCommunityPayment++;

		emit CommunityPaymentCreate(_communityId, id, msg.sender, _total);
	}

	/**
	 * @dev Make a payment to a community payment
	 * @param _communityPaymentId The id of the community payment
	 */
	function makePayment(
		uint256 _communityId,
		uint256 _communityPaymentId
	) public payable communityPaymentExistAndActive(_communityId, _communityPaymentId) {
		// TODO: check exists and ok comunityId <-> paymentId

		CommunityPayment storage cp = communityPayments[_communityPaymentId];
		uint256 amountSent = msg.value;

		// check for correct amount
		if (amountSent <= 0) revert Errors.AmountIsZero();
		if (amountSent > cp.amountTotal - cp.amountPaid) revert Errors.AmountIsGreaterThanTotal();

		cp.amountPaid += amountSent;
		communityPaymentsDetail[_communityPaymentId].push(PaymentInfo(msg.sender, amountSent));
		cp.paymentsLength++;

		emit CommunityPaymentSent(cp.communityId, _communityPaymentId, amountSent, msg.sender);

		checkAndSentFullCommunityPayment(cp, _communityPaymentId);
	}

	// TODO: how to improve not to read again storage
	function checkAndSentFullCommunityPayment(
		CommunityPayment storage _cp,
		uint256 _communityPaymentId
	) private {
		// if total amount reached
		if (_cp.amountPaid >= _cp.amountTotal) {
			_cp.isActive = false;
			_cp.isTransfered = true;

			// sent transfer to receiver
			address payable receiverPayable = payable(communities[_cp.communityId].receiverAddress);

			// make payment
			(bool callSuccess, ) = receiverPayable.call{value: _cp.amountTotal}('');
			if (!callSuccess) revert Errors.CallPayableFailed();

			amountTotalAggregated += _cp.amountTotal;
			emit CommunityPaymentTotal(
				_cp.communityId,
				_communityPaymentId,
				_cp.amountTotal,
				communities[_cp.communityId].receiverAddress,
				msg.sender
			);
		}
	}

	function getCommunityPayment(
		uint256 _communityPaymentId
	) public view returns (CommunityPayment memory) {
		CommunityPayment memory cp = communityPayments[_communityPaymentId];
		return cp;
	}

	/**
	 * @dev This modifier reverts if the caller is not the Community creator address.
	 */
	modifier onlyCommunityOwner(uint256 _idCommunity) {
		require(lastCommunity > _idCommunity, 'Community not exist');
		if (communities[_idCommunity].communityOwner != msg.sender)
			revert Errors.NotCommunityOwner();
		_;
	}

	/**
	 * @dev This modifier reverts if the caller is not the configured owner address.
	 */
	modifier onlyOwner() {
		if (msg.sender != owner) revert Errors.NotOwner();
		_;
	}

	/**
	 * @dev This modifier reverts if the caller is the Community Payment doesnt exist or is not active
	 */
	modifier communityPaymentExistAndActive(uint256 _communityId, uint256 _communityPaymentId) {
		Community memory c = communities[_communityId];
		if (communityPayments[_communityPaymentId].amountTotal == 0)
			revert Errors.CommunityPaymentNotExist();
		if (!communityPayments[_communityPaymentId].isActive)
			revert Errors.CommunityPaymentIsNotActive();
		_;
	}

	function getAllCommunities() public view returns (Community[] memory) {
		return communities;
	}

	/**
	 * @notice withdraw only fees when available
	 */
	function withdraw() public payable onlyOwner {
		require(amountTotalAggregated > 0, 'No tokens available');

		uint256 total = amountTotalAggregated;
		amountTotalAggregated = 0;
		(bool callSuccess, ) = payable(msg.sender).call{value: total}('');
		if (!callSuccess) revert Errors.CallPayableFailed();

		emit WithdrawFees(total, msg.sender);
	}
}
