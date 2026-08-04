import { describe, it } from "node:test";
import { expect } from "chai";
import { network } from "hardhat";
import { parseEther } from "viem";

describe("TaxiFareEscrow", async function () {
  const { viem } = await network.connect();

  async function deployFixture() {
    const [commuterClient, driverClient, otherClient] =
      await viem.getWalletClients();

    const escrow = await viem.deployContract("TaxiFareEscrow");
    const publicClient = await viem.getPublicClient();

    return { escrow, commuterClient, driverClient, otherClient, publicClient };
  }

  // Helper: run an async function and confirm it throws an error containing
  // the given text — used to check that the contract correctly rejects things.
  async function expectRevert(promise: Promise<unknown>, message: string) {
    try {
      await promise;
      throw new Error("Expected the transaction to revert, but it succeeded");
    } catch (err) {
      const text = String((err as Error).message ?? err);
      expect(text).to.include(message);
    }
  }

  it("creates a trip and locks the fare in the contract", async function () {
    const { escrow, commuterClient, driverClient, publicClient } =
      await deployFixture();

    const fare = parseEther("0.01");

    const escrowAsCommuter = await viem.getContractAt(
      "TaxiFareEscrow",
      escrow.address,
      { client: { wallet: commuterClient } }
    );

    await escrowAsCommuter.write.createTrip([driverClient.account.address], {
      value: fare,
    });

    const balance = await publicClient.getBalance({ address: escrow.address });
    expect(balance).to.equal(fare);

    const state = await escrow.read.getTripState([0n]);
    expect(state).to.equal(0); // TripState.Created
  });

  it("releases the fare to the driver once both sides confirm", async function () {
    const { escrow, commuterClient, driverClient, publicClient } =
      await deployFixture();

    const fare = parseEther("0.01");

    const escrowAsCommuter = await viem.getContractAt(
      "TaxiFareEscrow",
      escrow.address,
      { client: { wallet: commuterClient } }
    );
    const escrowAsDriver = await viem.getContractAt(
      "TaxiFareEscrow",
      escrow.address,
      { client: { wallet: driverClient } }
    );

    await escrowAsCommuter.write.createTrip([driverClient.account.address], {
      value: fare,
    });

    await escrowAsCommuter.write.confirmComplete([0n]);
    let state = await escrow.read.getTripState([0n]);
    expect(state).to.equal(0); // still Created, only one side confirmed

    await escrowAsDriver.write.confirmComplete([0n]);
    state = await escrow.read.getTripState([0n]);
    expect(state).to.equal(1); // TripState.Completed

    const balance = await publicClient.getBalance({ address: escrow.address });
    expect(balance).to.equal(0n);
  });

  it("blocks someone who is not the commuter or driver from confirming", async function () {
    const { escrow, commuterClient, driverClient, otherClient } =
      await deployFixture();

    const fare = parseEther("0.01");

    const escrowAsCommuter = await viem.getContractAt(
      "TaxiFareEscrow",
      escrow.address,
      { client: { wallet: commuterClient } }
    );
    const escrowAsOther = await viem.getContractAt(
      "TaxiFareEscrow",
      escrow.address,
      { client: { wallet: otherClient } }
    );

    await escrowAsCommuter.write.createTrip([driverClient.account.address], {
      value: fare,
    });

    await expectRevert(
      escrowAsOther.write.confirmComplete([0n]),
      "Only the commuter or driver can confirm this trip"
    );
  });

  it("freezes a trip once a dispute is raised", async function () {
    const { escrow, commuterClient, driverClient } = await deployFixture();

    const fare = parseEther("0.01");

    const escrowAsCommuter = await viem.getContractAt(
      "TaxiFareEscrow",
      escrow.address,
      { client: { wallet: commuterClient } }
    );

    await escrowAsCommuter.write.createTrip([driverClient.account.address], {
      value: fare,
    });

    await escrowAsCommuter.write.raiseDispute([0n]);

    const state = await escrow.read.getTripState([0n]);
    expect(state).to.equal(2); // TripState.Disputed

    await expectRevert(
      escrowAsCommuter.write.confirmComplete([0n]),
      "Trip is not open for confirmation"
    );
  });
});