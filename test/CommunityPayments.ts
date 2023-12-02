import { anyValue } from '@nomicfoundation/hardhat-chai-matchers/withArgs';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, Signer, BigNumberish } from 'ethers';
const { loadFixture } = require('@nomicfoundation/hardhat-toolbox/network-helpers');
import { CommunityPayments, CommunityPayments__factory } from '../typechain-types';

const COMMUNITY_TEST_NAME: string = 'Test Community';

const createCommunity = async (
	communityPayments: CommunityPayments,
	receiveAddress: string,
	owner: Signer
) => {
	let txResponse = await communityPayments.createCommunity(COMMUNITY_TEST_NAME, receiveAddress);
	const txReceipt = await txResponse.wait();

	return txReceipt;
};

const createCommunityPayment = async (
	communityPayments: CommunityPayments,
	owner: Signer,
	amount: number,
	communityId: number
) => {
	//owners call createCommunityPayment

	let txResponse = await communityPayments
		.connect(owner)
		.createCommunityPayment(communityId, amount);

	const txReceipt = await txResponse.wait();

	return txReceipt;
};

const makePayment = async (
	communityPayments: CommunityPayments,
	another: Signer,
	amount: number,
	communityId: number,
	_communityPaymentId: number
) => {
	// send amount in the call to make payment
	let txResponse = await communityPayments
		.connect(another)
		.makePayment(communityId, _communityPaymentId, { value: amount });

	const txReceipt = await txResponse.wait();

	return txReceipt;
};

describe('Community Payments Testing', function () {
	async function deployFixture() {
		let communityPayments: CommunityPayments;

		const [owner, bobAccount, carlosAccount, receiveAddress] = await ethers.getSigners();
		communityPayments = await new CommunityPayments__factory(owner).deploy();

		return { owner, bobAccount, carlosAccount, receiveAddress, communityPayments };
	}

	before(async function () {});

	it('Should create a community', async function () {
		const { owner, otherAccount, receiveAddress, communityPayments } = await loadFixture(
			deployFixture
		);

		let txReceipt = await createCommunity(communityPayments, receiveAddress, owner);

		await expect(txReceipt)
			.to.emit(communityPayments, 'CommunityCreate')
			.withArgs(0, COMMUNITY_TEST_NAME, receiveAddress.address, owner.address);
	});

	it('Should create a community payment', async function () {
		const { owner, otherAccount, receiveAddress, communityPayments } = await loadFixture(
			deployFixture
		);

		await createCommunity(communityPayments, receiveAddress, owner);
		let txReceipt = await createCommunityPayment(communityPayments, owner, 100, 0);

		await expect(txReceipt)
			.to.emit(communityPayments, 'CommunityPaymentCreate')
			.withArgs(0, 0, owner.address, 100);
	});

	it('Should pay a total community payment', async function () {
		const { owner, bobAccount, receiveAddress, communityPayments } = await loadFixture(
			deployFixture
		);

		await createCommunity(communityPayments, receiveAddress, owner);
		await createCommunityPayment(communityPayments, owner, 100, 0);

		let txReceipt = makePayment(communityPayments, bobAccount, 100, 0, 0);

		await expect(txReceipt)
			.to.emit(communityPayments, 'CommunityPaymentSent')
			.withArgs(0, 0, 100, bobAccount.address);
	});

	it('Should pay a total community payment in two payments', async function () {
		const { owner, bobAccount, carlosAccount, receiveAddress, communityPayments } =
			await loadFixture(deployFixture);

		// get the initial amount of the receive address
		let initialReceiveAddressBalance = await ethers.provider.getBalance(receiveAddress.address);

		await createCommunity(communityPayments, receiveAddress, owner);
		await createCommunityPayment(communityPayments, owner, 100, 0);

		let data = await communityPayments.getCommunityPayment(0);

		expect(data.isTransfered).to.equal(false);

		makePayment(communityPayments, bobAccount, 60, 0, 0);
		let txReceipt = makePayment(communityPayments, bobAccount, 40, 0, 0);

		// expect the second payment event to be emitted
		await expect(txReceipt)
			.to.emit(communityPayments, 'CommunityPaymentSent')
			.withArgs(0, 0, 40, bobAccount.address);

		// except the total amount event to be emitted
		await expect(txReceipt)
			.to.emit(communityPayments, 'CommunityPaymentTotal')
			.withArgs(0, 0, 100, receiveAddress.address, bobAccount.address);

		// expect the total amount to be in the receive address plus initialReceiveAddressBalance
		let finalReceiveAddressBalance = await ethers.provider.getBalance(receiveAddress.address);

		data = await communityPayments.getCommunityPayment(0);

		expect(data.isTransfered).to.equal(true);

		expect(finalReceiveAddressBalance).to.equal(
			BigInt(initialReceiveAddressBalance) + BigInt(100)
		);
	});
});
