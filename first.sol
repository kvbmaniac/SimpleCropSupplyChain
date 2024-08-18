// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleCropSupplyChain {

    // Variables to store crop details
    string public cropName;
    string public origin;
    address public currentOwner;
    string[] public history;
    bool public isDelivered;

    // Event to log crop creation
    event CropCreated(string name, string origin, address owner);

    // Event to log crop transfer
    event CropTransferred(address newOwner);

    // Event to log crop delivery
    event CropDelivered(address finalOwner);

    // Function to create a new crop
    function createCrop(string memory _name, string memory _origin) public {
        require(bytes(cropName).length == 0, "Crop already created");

        cropName = _name;
        origin = _origin;
        currentOwner = msg.sender;
        history.push(_origin);

        emit CropCreated(_name, _origin, msg.sender);
    }

    // Function to transfer crop ownership
    function transferCrop(address _newOwner) public {
        require(bytes(cropName).length != 0, "Crop not created yet");
        require(!isDelivered, "Crop already delivered");
        require(msg.sender == currentOwner, "Only current owner can transfer");

        currentOwner = _newOwner;
        history.push("Transferred to new owner");

        emit CropTransferred(_newOwner);
    }

    // Function to mark crop as delivered
    function deliverCrop() public {
        require(bytes(cropName).length != 0, "Crop not created yet");
        require(!isDelivered, "Crop already delivered");
        require(msg.sender == currentOwner, "Only current owner can deliver");

        isDelivered = true;

        emit CropDelivered(currentOwner);
    }

    // Function to get the crop history
    function getCropHistory() public view returns (string[] memory) {
        return history;
    }
}