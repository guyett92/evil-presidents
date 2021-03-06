// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";
// Helper we wrote to encode in Base64
import "./libraries/Base64.sol";

contract MyEpicGame is ERC721 {

    // Can add attributes here (ex. defense, crit chance, etc.)
    struct CharacterAttributes {
        uint characterIndex;
        string name;
        string imageURI;
        uint hp;
        uint maxHp;
        uint attackDamage;
    }

    // tokenId is the unique identifier
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Default data held here
    CharacterAttributes[] defaultCharacters;

    // Mapping NFT's tokenId to attributes
    mapping(uint256 => CharacterAttributes) public nftHolderAttributes;

    // Mapping from address to NFT tokenId
    mapping(address => uint256) public nftHolders;

    // Events used to showcase character is minted after being mined and attacks work
    event CharacterNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);
    event AttackComplete(uint newBossHp, uint newPlayerHp);

    struct BigBoss {
        string name;
        string imageURI;
        uint hp;
        uint maxHp;
        uint attackDamage;
    }

    BigBoss public bigBoss;

    // Data passed into the contract upon initialization from run.js
    // Below that, we give our token a name and abbreviation
    constructor(string[] memory characterNames, string[] memory characterImageURIs, uint[] memory characterHp, uint[] memory characterAttackDmg, string memory bossName, string memory bossImageURI, uint bossHp, uint bossAttackDamage)
        ERC721("Heroes", "HERO")
    {
        // Initialize big boss
        bigBoss = BigBoss({
            name: bossName,
            imageURI: bossImageURI,
            hp: bossHp,
            maxHp: bossHp,
            attackDamage: bossAttackDamage
        });

        console.log("Done initializing boss %s w/ HP %s, img %s", bigBoss.name, bigBoss.hp, bigBoss.imageURI);

        // Looping through all characters and storing the values in the contract
        for(uint i = 0; i < characterNames.length; i += 1) {
            defaultCharacters.push(CharacterAttributes({
                characterIndex: i,
                name: characterNames[i],
                imageURI: characterImageURIs[i],
                hp: characterHp[i],
                maxHp: characterHp[i],
                attackDamage: characterAttackDmg[i]
            }));

            CharacterAttributes memory c = defaultCharacters[i];
            console.log("Done initializing %s w/ HP %s, img %s", c.name, c.hp, c.imageURI);
        }
        // Increment tokenId
        _tokenIds.increment();

    }

    // Get NFT based on characterId
    function mintCharacterNFT(uint _characterIndex) external {
        // Get current tokenId
        uint256 newItemId = _tokenIds.current();

        // Assigns tokenId to wallet address Probably the most important thing here
        _safeMint(msg.sender, newItemId);

        // Map tokenId to attributes
        nftHolderAttributes[newItemId] = CharacterAttributes({
            characterIndex: _characterIndex,
            name: defaultCharacters[_characterIndex].name,
            imageURI: defaultCharacters[_characterIndex].imageURI,
            hp: defaultCharacters[_characterIndex].hp,
            maxHp: defaultCharacters[_characterIndex].hp,
            attackDamage: defaultCharacters[_characterIndex].attackDamage
        });

        console.log("Minted NFT w/ tokenId %s and characterIndex %s", newItemId, _characterIndex);

        // Makes it easy to see who owns what NFT
        nftHolders[msg.sender] = newItemId;

        // Increment tokenId for the next person
        _tokenIds.increment();

        // Similar to a hook, catches the events
        emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        // Retrieves specific NFTs data by querying it using the _tokenId
        CharacterAttributes memory charAttributes = nftHolderAttributes[_tokenId];

        string memory strHp = Strings.toString(charAttributes.hp);
        string memory strMaxHp = Strings.toString(charAttributes.maxHp);
        string memory strAttackDamage = Strings.toString(charAttributes.attackDamage);

        string memory json = Base64.encode(
            bytes(
                string(
                    // Formats data needed for Opensea, etc.
                    abi.encodePacked(
                        '{"name": "',
                        charAttributes.name,
                        ' -- NFT #: ',
                        Strings.toString(_tokenId),
                        '", "description": "This is an NFT that lets people play in the game Metaverse Slayer!", "image": "',
                        charAttributes.imageURI,
                        '", "attributes": [ { "trait_type": "Health Points", "value": ',strHp,', "max_value":',strMaxHp,'}, { "trait_type": "Attack Damage", "value": ',
                        strAttackDamage,'} ]}'
                    )
                )
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output; 
    }

    function attackBoss() public {
        // Get thje state of the player's NFT
        uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
        CharacterAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];
        console.log("\nPlayer w/ character %s about to attack. Has %s HP and %s AD", player.name, player.hp, player.attackDamage);
        console.log("Boss %s has %s HP and %s AD", bigBoss.name, bigBoss.hp, bigBoss.attackDamage);

        // Make sure the player has more than 0 HP
        require (
            player.hp > 0,
            "Error: character must have HP to attack the boss."
        );

        // Make sure the boss has more than 0 HP.
        require (
            bigBoss.hp > 0,
            "Error: boss must have HP to be attacked."
        );

        // Enable player to attack boss and boss to attack player and handling negative numbers since uint can't be negative
        if (bigBoss.hp < player.attackDamage) {
            bigBoss.hp = 0;
        } else {
            bigBoss.hp = bigBoss.hp - player.attackDamage;
        }

        if (player.hp < bigBoss.attackDamage) {
            player.hp = 0;
        } else {
            player.hp = player.hp - bigBoss.attackDamage;
        }

        console.log("Boss attacked player. New player hp: %s\n", player.hp);

        // Utilize the events
        emit AttackComplete(bigBoss.hp, player.hp);

    }

    function checkIfUserHasNFT() public view returns (CharacterAttributes memory) {
        // Get the tokenId of the user's character NFT
        uint256 userNftTokenId = nftHolders[msg.sender];
        // If the user has a tokenid in the map, return their character, otherwise, return an empty character
        if (userNftTokenId > 0) {
            return nftHolderAttributes[userNftTokenId];
        } else {
            CharacterAttributes memory emptyStruct;
            return emptyStruct;
        }
    }

    function getAllDefaultCharacters() public view returns (CharacterAttributes[] memory) {
        return defaultCharacters;
    }

    function getBigBoss() public view returns (BigBoss memory) {
        return bigBoss;
    }

}