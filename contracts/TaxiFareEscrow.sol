// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Taxi Rank Fare Escrow
/// @notice Holds a commuter's fare in escrow until both parties confirm the trip is complete.
/// @dev Day 1 version: trip creation + fare deposit only.
///      Confirmation and release logic will be added in later commits.
contract TaxiFareEscrow {
    enum TripState {
        Created,
        Completed,
        Disputed
    }

    struct Trip {
        address commuter;
        address driver;
        uint256 fare;
        TripState state;
    }

    // Each trip gets its own id so multiple trips can exist at once.
    uint256 public nextTripId;

    mapping(uint256 => Trip) public trips;

    event TripCreated(
        uint256 indexed tripId,
        address indexed commuter,
        address indexed driver,
        uint256 fare
    );

    /// @notice Commuter starts a trip by depositing the fare for a named driver.
    /// @param driver The wallet address of the driver for this trip.
    function createTrip(address driver) external payable {
        require(driver != address(0), "Driver address cannot be zero");
        require(msg.value > 0, "Fare must be greater than zero");

        uint256 tripId = nextTripId;

        trips[tripId] = Trip({
            commuter: msg.sender,
            driver: driver,
            fare: msg.value,
            state: TripState.Created
        });

        nextTripId++;

        emit TripCreated(tripId, msg.sender, driver, msg.value);
    }

    /// @notice Returns the current state of a trip.
    function getTripState(uint256 tripId) external view returns (TripState) {
        return trips[tripId].state;
    }

    // --- Coming in later commits ---
    // function confirmComplete(uint256 tripId) external { ... }
    // function releaseFare(uint256 tripId) internal { ... }
    // function raiseDispute(uint256 tripId) external { ... }
}