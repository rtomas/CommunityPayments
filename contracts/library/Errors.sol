// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Errors {
	error AmountIsZero();
	error AmountIsGreaterThanTotal();
	error AddressIsZero();
	error CommunityPaymentNotExist();
	error CommunityPaymentIsNotActive();
	error CommunityPaymentIsNotRevertActive();
	error CommunityPaymentsIndividualError();
	error NotOwner();
	error CallPayableFailed();
	error CallExcessReceiverPayableFailed();
	error NotCommunityPaymentOwner();
	error ZeroCommunityPayments();
	error TotalFeeIsTooSmall();
	error NotCommunityOwner();
}
