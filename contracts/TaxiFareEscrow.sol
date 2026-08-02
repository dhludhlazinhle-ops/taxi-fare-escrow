// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Taxi Rank Fare Escrow
/// @notice Holds a commuter's fare in escrow until both parties confirm the trip is complete.
/// @dev Day 2 version: adds two-sided confirmation and automatic fare release.
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
        bool commuterConfirmed;
        bool driverConfirmed;
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

    event TripConfirmed(uint256 indexed tripId, address indexed confirmedBy);

    event TripCompleted(uint256 indexed tripId, address indexed driver, uint256 fare);

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
            state: TripState.Created,
            commuterConfirmed: false,
            driverConfirmed: false
        });

        nextTripId++;

        emit TripCreated(tripId, msg.sender, driver, msg.value);
    }

    /// @notice Called by either the commuter or the driver to confirm the trip is done.
    /// @dev Once both sides have confirmed, the fare is released to the driver automatically.
    /// @param tripId The id of the trip being confirmed.
    function confirmComplete(uint256 tripId) external {
        Trip storage trip = trips[tripId];

        require(trip.commuter != address(0), "Trip does not exist");
        require(trip.state == TripState.Created, "Trip is not open for confirmation");
        require(
            msg.sender == trip.commuter || msg.sender == trip.driver,
            "Only the commuter or driver can confirm this trip"
        );

        if (msg.sender == trip.commuter) {
            require(!trip.commuterConfirmed, "Commuter already confirmed");
            trip.commuterConfirmed = true;
        } else {
            require(!trip.driverConfirmed, "Driver already confirmed");
            trip.driverConfirmed = true;
        }

        emit TripConfirmed(tripId, msg.sender);

        if (trip.commuterConfirmed && trip.driverConfirmed) {
            _releaseFare(tripId);
        }
    }

    /// @dev Internal function: sends the fare to the driver and marks the trip completed.
    ///      Only ever called once both sides have confirmed.
    function _releaseFare(uint256 tripId) internal {
        Trip storage trip = trips[tripId];

        trip.state = TripState.Completed;

        uint256 fareToPay = trip.fare;
        trip.fare = 0; // clear before sending, to guard against re-entrancy

        (bool success, ) = payable(trip.driver).call{value: fareToPay}("");
        require(success, "Fare transfer to driver failed");

        emit TripCompleted(tripId, trip.driver, fareToPay);
    }

    /// @notice Returns the current state of a trip.
    function getTripState(uint256 tripId) external view returns (TripState) {
        return trips[tripId].state;
    }

    // --- Coming in later commits ---
    // function raiseDispute(uint256 tripId) external { ... }
}