// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// This contract implements a simple supply chain management system for crops.
contract SimpleCropSupplyChain {
    // The Crop struct stores all the relevant details of a crop.
    struct Crop {
        string name; // The name of the crop (e.g., Maize, Wheat).
        string origin; // The place of origin of the crop.
        string destination; // The intended destination of the crop.
        address currentOwner; // The current owner of the crop, typically the party responsible for it.
        bool isDelivered; // A flag indicating whether the crop has been delivered to its final destination.
    }

    // The History struct keeps a record of significant events associated with a crop.
    struct History {
        string eventDetail; // A description of the event (e.g., "Crop created", "Transferred to new owner").
        address involvedParty; // The address of the party involved in the event.
        uint256 timestamp; // The timestamp of when the event occurred.
    }

    // Mapping of crop IDs to Crop structs, storing all created crops.
    mapping(uint256 => Crop) private crops;

    // Mapping of crop IDs to arrays of History structs, storing the history of each crop.
    mapping(uint256 => History[]) private cropHistories;

    // Mapping of crop names to their corresponding crop IDs.
    mapping(string => uint256) private cropIdsByName;

    // Counter to generate unique crop IDs.
    uint256 private cropCounter;

    // Event emitted when a new crop is created.
    event CropCreated(
        uint256 indexed cropId, // The unique ID of the crop.
        string name, // The name of the crop.
        string origin, // The place of origin of the crop.
        string destination, // The destination of the crop.
        address owner // The address of the owner who created the crop.
    );

    // Event emitted when a crop is transferred to a new owner.
    event CropTransferred(
        uint256 indexed cropId, // The unique ID of the crop.
        string name, // The name of the crop.
        string origin, // The place of origin of the crop.
        string destination, // The destination of the crop.
        address indexed from, // The address of the previous owner.
        address indexed to // The address of the new owner.
    );

    // Event emitted when a crop is marked as delivered.
    event CropDelivered(
        uint256 indexed cropId, // The unique ID of the crop.
        string name, // The name of the crop.
        string origin, // The place of origin of the crop.
        string destination, // The destination of the crop.
        address finalOwner // The address of the final owner who received the crop.
    );

    // Modifier to restrict actions to only the current owner of a crop.
    modifier onlyOwner(uint256 _cropId) {
        // Check if the caller is the current owner of the crop.
        require(
            msg.sender == crops[_cropId].currentOwner,
            "Not the current owner"
        );
        _;
    }

    // Modifier to check if a crop exists (i.e., it has been created).
    modifier cropExists(uint256 _cropId) {
        // Ensure the crop has a valid name, which indicates its existence.
        require(bytes(crops[_cropId].name).length != 0, "Crop does not exist");
        _;
    }

    // Modifier to check if a crop has not yet been delivered.
    modifier notDelivered(uint256 _cropId) {
        // Ensure the crop has not been marked as delivered.
        require(!crops[_cropId].isDelivered, "Crop already delivered");
        _;
    }

    // Function to create a new crop in the system.
    function createCrop(
        string calldata _name, // The name of the crop.
        string calldata _origin, // The origin of the crop.
        string calldata _destination // The destination of the crop.
    ) external {
        // Ensure that the crop has a valid name, origin, and destination.
        require(bytes(_name).length > 0, "Crop name is required");
        require(bytes(_origin).length > 0, "Crop origin is required");
        require(bytes(_destination).length > 0, "Crop destination is required");

        // Create a new Crop struct and store it in the mapping with a unique crop ID.
        crops[cropCounter] = Crop({
            name: _name,
            origin: _origin,
            destination: _destination,
            currentOwner: msg.sender, // The caller of the function is set as the current owner.
            isDelivered: false // Initially, the crop is not marked as delivered.
        });

        // Map the crop name to the crop ID for easy lookup.
        cropIdsByName[_name] = cropCounter;

        // Add an entry to the crop's history indicating its creation.
        addHistory(cropCounter, "Crop created", msg.sender);

        // Emit an event to notify that a new crop has been created.
        emit CropCreated(cropCounter, _name, _origin, _destination, msg.sender);

        // Increment the crop counter to ensure the next crop gets a unique ID.
        cropCounter++;
    }

    // Function to transfer ownership of a crop to a new owner.
    function transferCrop(
        uint256 _cropId,
        address _newOwner
    )
        external
        cropExists(_cropId) // Ensure the crop exists.
        notDelivered(_cropId) // Ensure the crop has not been delivered.
        onlyOwner(_cropId) // Ensure the caller is the current owner of the crop.
    {
        // Ensure the new owner's address is valid (not the zero address).
        require(_newOwner != address(0), "New owner cannot be zero address");

        // Store the current owner before transferring ownership.
        address previousOwner = crops[_cropId].currentOwner;

        // Update the crop's current owner to the new owner.
        crops[_cropId].currentOwner = _newOwner;

        // Add an entry to the crop's history indicating the transfer.
        addHistory(_cropId, "Transferred to new owner", _newOwner);

        // Emit an event to notify that the crop has been transferred.
        emit CropTransferred(
            _cropId,
            crops[_cropId].name,
            crops[_cropId].origin,
            crops[_cropId].destination,
            previousOwner,
            _newOwner
        );
    }

    // Function to mark a crop as delivered to its final destination.
    function deliverCrop(
        uint256 _cropId
    )
        external
        cropExists(_cropId) // Ensure the crop exists.
        notDelivered(_cropId) // Ensure the crop has not been delivered.
        onlyOwner(_cropId) // Ensure the caller is the current owner of the crop.
    {
        // Mark the crop as delivered.
        crops[_cropId].isDelivered = true;

        // Add an entry to the crop's history indicating its delivery.
        addHistory(_cropId, "Crop delivered", msg.sender);

        // Emit an event to notify that the crop has been delivered.
        emit CropDelivered(
            _cropId,
            crops[_cropId].name,
            crops[_cropId].origin,
            crops[_cropId].destination,
            crops[_cropId].currentOwner
        );
    }

    // Function to update the destination of a crop.
    function updateDestination(
        uint256 _cropId,
        string calldata _newDestination
    )
        external
        cropExists(_cropId) // Ensure the crop exists.
        notDelivered(_cropId) // Ensure the crop has not been delivered.
        onlyOwner(_cropId) // Ensure the caller is the current owner of the crop.
    {
        // Ensure that the new destination is valid (non-empty).
        require(
            bytes(_newDestination).length > 0,
            "New destination is required"
        );

        // Update the crop's destination to the new destination.
        crops[_cropId].destination = _newDestination;

        // Add an entry to the crop's history indicating the destination update.
        addHistory(_cropId, "Destination updated", msg.sender);
    }

    // Function to retrieve the history of a specific crop.
    function getCropHistory(
        uint256 _cropId
    )
        external
        view
        cropExists(_cropId) // Ensure the crop exists.
        returns (History[] memory)
    {
        // Return the array of history records for the given crop ID.
        return cropHistories[_cropId];
    }

    // Function to retrieve the name of a specific crop by its ID.
    function getCropNameById(
        uint256 _cropId
    )
        external
        view
        cropExists(_cropId) // Ensure the crop exists.
        returns (string memory)
    {
        // Return only the name of the Crop associated with the given crop ID.
        return crops[_cropId].name;
    }

    // Function to retrieve the ID of a crop given its name.
    function getIdByCropName(
        string calldata _name
    ) external view returns (uint256) {
        // Get the crop ID associated with the given name.
        uint256 cropId = cropIdsByName[_name];

        // Ensure the crop exists by checking if the name associated with cropId is the same as _name.
        // This prevents returning 0 for unregistered crops.
        require(
            cropId != 0 &&
                keccak256(abi.encodePacked(crops[cropId].name)) ==
                keccak256(abi.encodePacked(_name)),
            "Crop not found"
        );

        // Return the crop ID.
        return cropId;
    }

    // Function to retrieve all details of a specific crop.
    function getCropDetails(
        uint256 _cropId
    )
        external
        view
        cropExists(_cropId) // Ensure the crop exists.
        returns (
            string memory name, // The name of the crop.
            string memory origin, // The origin of the crop.
            string memory destination, // The destination of the crop.
            address currentOwner, // The current owner of the crop.
            bool isDelivered // The delivery status of the crop.
        )
    {
        // Get the Crop struct associated with the given crop ID.
        Crop storage crop = crops[_cropId];

        // Return all the details of the crop.
        return (
            crop.name,
            crop.origin,
            crop.destination,
            crop.currentOwner,
            crop.isDelivered
        );
    }

    // Internal function to add an event to the history of a crop.
    function addHistory(
        uint256 _cropId, // The ID of the crop.
        string memory _eventDetail, // The description of the event.
        address _involvedParty // The address of the party involved in the event.
    ) internal {
        // Push a new History struct to the history array for the given crop ID.
        cropHistories[_cropId].push(
            History({
                eventDetail: _eventDetail,
                involvedParty: _involvedParty,
                timestamp: block.timestamp // Record the current block timestamp.
            })
        );
    }
}
