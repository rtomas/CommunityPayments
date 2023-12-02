# Community Payments Smart Contract

## Overview

This smart contract, named **CommunityPayments**, facilitates the collection of payments via cryptocurrency for businesses, enabling seamless transactions among multiple participants. The contract is designed to manage community-specific payments, providing a structured and secure approach for handling financial transactions within a community.

## Testing

The smart contract was tested using the [Hardhat](https://hardhat.org/) development environment and [Ethers.js](https://docs.ethers.io/v5/) library.

run `yarn` to install the required dependencies.

run `yarn hardhat test` to run the tests.

## Features

### Community Creation

-   **Function:** `createCommunity`
    -   **Description:** Creates a new community and returns its unique identifier.
    -   **Parameters:**
        -   `_name` (string): The name of the community.
        -   `_receive` (address): The address of the payment receiver.
    -   **Access:** Public

### Community Payment Creation

-   **Function:** `createCommunityPayment`
    -   **Description:** Creates a new community payment and returns its unique identifier.
    -   **Parameters:**
        -   `_communityId` (uint256): The identifier of the community.
        -   `_total` (uint256): The total amount of the payment.
    -   **Access:** Public (only accessible by the community owner)

### Payment Submission

-   **Function:** `makePayment`
    -   **Description:** Allows a participant to make a payment to a community payment.
    -   **Parameters:**
        -   `_communityId` (uint256): The identifier of the community.
        -   `_communityPaymentId` (uint256): The identifier of the community payment.
    -   **Access:** Public

### Withdrawal of Fees

-   **Function:** `withdraw`
    -   **Description:** Allows the contract owner to withdraw accumulated fees.
    -   **Access:** Only accessible by the contract owner

## Event Logging

The smart contract logs essential actions through events:

-   `CommunityCreate`: Logs the creation of a new community.
-   `CommunityPaymentCreate`: Logs the creation of a community payment.
-   `CommunityPaymentSent`: Logs when a payment is successfully made to a community payment.
-   `CommunityPaymentTotal`: Logs the total amount transferred to the receiver upon completion of a community payment.
-   `WithdrawFees`: Logs the withdrawal of fees by the contract owner.
-   `RevertComunityPayments`: Logs the deactivation of a community payment by the owner.

## Modifiers

-   `onlyOwner`: Restricts access to functions that can only be executed by the contract owner.
-   `onlyCommunityOwner`: Restricts access to functions that can only be executed by the owner of a specific community.

## Important Notes

-   The contract includes error handling to ensure secure and reliable operation.
-   The contract owner can withdraw accumulated fees through the `withdraw` function.
-   This smart contract was not audited by a third party. Use at your own risk.

## Developer Information

-   **Developer:** Tomas Rawski
-   **License:** MIT
-   **Version:** 0.8.9
-   **Solidity Version:** ^0.8.9

## To Do

-   Allow the contract owner to deactivate a community payment.
-   Allow the contract owner to deactivate a community.
-   Allow to cancel a payment if the total amount is not reached.
-   Add fees in case of cancellation.
