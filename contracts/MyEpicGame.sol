// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";
import "./libraries/Base64.sol";

contract MyEpicGame is ERC721 {
    struct CharacterAttributes {
        uint256 characterIndex;
        string name;
        string imageURI;
        uint256 hp;
        uint256 maxHp;
        uint256 attackDamage;
        uint8 level;
        uint8 maxLevel;
        uint256 earnedXp;
        uint256 nextLevelXp;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    CharacterAttributes[] defaultCharacters;
    uint8 _playerMaxLevel = 99;

    // tokenId => NFTs attributes.
    mapping(uint256 => CharacterAttributes) public nftHolderAttributes;
    // holder address => the NFTs tokenId.
    mapping(address => uint256) public nftHolders;

    struct BigBoss {
        string name;
        string imageURI;
        uint256 hp;
        uint256 maxHp;
        uint256 attackDamage;
    }
    BigBoss public bigBoss;

    event CharacterNFTMinted(
        address sender,
        uint256 tokenId,
        uint256 characterIndex
    );
    event AttackComplete(uint256 newBossHp, uint256 newPlayerHp);

    constructor(
        string[] memory characterNames,
        string[] memory characterImageURIs,
        uint256[] memory characterHp,
        uint256[] memory characterAttackDmg,
        string memory bossName,
        string memory bossImageURI,
        uint256 bossHp,
        uint256 bossAttackDamage
    ) ERC721("Hogwards Collection", "HOG") {
        bigBoss = BigBoss({
            name: bossName,
            imageURI: bossImageURI,
            hp: bossHp,
            maxHp: bossHp,
            attackDamage: bossAttackDamage
        });

        console.log(
            "Done initializing boss %s w/ HP %s, img %s",
            bigBoss.name,
            bigBoss.hp,
            bigBoss.imageURI
        );

        for (uint256 i = 0; i < characterNames.length; i += 1) {
            defaultCharacters.push(
                CharacterAttributes({
                    characterIndex: i,
                    name: characterNames[i],
                    imageURI: characterImageURIs[i],
                    hp: characterHp[i],
                    maxHp: characterHp[i],
                    attackDamage: characterAttackDmg[i],
                    level: 1,
                    maxLevel: _playerMaxLevel,
                    earnedXp: 0,
                    nextLevelXp: 10
                })
            );

            CharacterAttributes memory c = defaultCharacters[i];

            console.log(
                "Done initializing %s w/ HP %s, img ipfs://%s",
                c.name,
                c.hp,
                c.imageURI
            );
        }
        _tokenIds.increment(); // for making first tokenID = 1
    }

    function mintCharacterNFT(uint256 _characterIndex) external {
        uint256 newItemId = _tokenIds.current();

        // Assigns the tokenId to the caller's wallet address.
        _safeMint(msg.sender, newItemId);

        nftHolderAttributes[newItemId] = CharacterAttributes({
            characterIndex: _characterIndex,
            name: defaultCharacters[_characterIndex].name,
            imageURI: defaultCharacters[_characterIndex].imageURI,
            hp: defaultCharacters[_characterIndex].hp,
            maxHp: defaultCharacters[_characterIndex].maxHp,
            attackDamage: defaultCharacters[_characterIndex].attackDamage,
            level: defaultCharacters[_characterIndex].level,
            maxLevel: defaultCharacters[_characterIndex].maxLevel,
            earnedXp: defaultCharacters[_characterIndex].earnedXp,
            nextLevelXp: defaultCharacters[_characterIndex].nextLevelXp

        });

        console.log(
            "Minted NFT w/ tokenId %s and characterIndex %s",
            newItemId,
            _characterIndex
        );

        nftHolders[msg.sender] = newItemId;
        _tokenIds.increment();
        emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        CharacterAttributes memory charAttributes = nftHolderAttributes[
            _tokenId
        ];

        string memory strHp = Strings.toString(charAttributes.hp);
        string memory strMaxHp = Strings.toString(charAttributes.maxHp);
        string memory strAttackDamage = Strings.toString(
            charAttributes.attackDamage
        );
        string memory level = Strings.toString(charAttributes.level);
        string memory maxLevel = Strings.toString(charAttributes.maxLevel);

        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                charAttributes.name,
                " -- NFT #: ",
                Strings.toString(_tokenId),
                '", "description": "An epic NFT", "image": "ipfs://',
                charAttributes.imageURI,
                '", "attributes": [ { "trait_type": "Health Points", "value": ',
                strHp,
                ', "max_value":',
                strMaxHp,
                '},{ "trait_type": "Level", "value": ',
                level,
                ', "max_level":',
                maxLevel,
                '},{ "trait_type": "Attack Damage", "value": ',
                strAttackDamage,
                "} ]}"
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function attackBoss() public {
        uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
        CharacterAttributes storage player = nftHolderAttributes[
            nftTokenIdOfPlayer
        ];
        console.log(
            "\nPlayer w/ character %s about to attack. Has %s HP and %s AD",
            player.name,
            player.hp,
            player.attackDamage
        );
        console.log(
            "Boss %s has %s HP and %s AD",
            bigBoss.name,
            bigBoss.hp,
            bigBoss.attackDamage
        );
        require(player.hp > 0, "Error: character must have HP to attack boss.");

        require(bigBoss.hp > 0, "Error: boss must have HP to attack boss.");

        // Allow player to attack boss.
        if (bigBoss.hp < player.attackDamage) {
            bigBoss.hp = 0;
        } else {
            bigBoss.hp = bigBoss.hp - player.attackDamage;
            earnXp(nftTokenIdOfPlayer, 6);
        }
        // Allow boss to attack player.
        if (player.hp < bigBoss.attackDamage) {
            player.hp = 0;
        } else {
            player.hp = player.hp - bigBoss.attackDamage;
        }
        // Console for ease.
        console.log("Player attacked boss. New boss hp: %s", bigBoss.hp);
        console.log("Boss attacked player. New player hp: %s\n", player.hp);
        emit AttackComplete(bigBoss.hp, player.hp);
    }

    function checkIfUserHasNFT()
        public
        view
        returns (CharacterAttributes memory)
    {
        // Get the tokenId of the user's character NFT
        uint256 userNftTokenId = nftHolders[msg.sender];
        // If the user has a tokenId in the map, return their character.
        if (userNftTokenId > 0) {
            return nftHolderAttributes[userNftTokenId];
        }
        // Else, return an empty character.
        else {
            CharacterAttributes memory emptyStruct;
            return emptyStruct;
        }
    }

    function getAllDefaultCharacters()
        public
        view
        returns (CharacterAttributes[] memory)
    {
        return defaultCharacters;
    }

    function getBigBoss() public view returns (BigBoss memory) {
        return bigBoss;
    }

    function earnXp(uint256 _tokenId, uint256 _amount) public {
        CharacterAttributes storage player = nftHolderAttributes[_tokenId];
        if(player.earnedXp + _amount >= player.nextLevelXp) {
            player.earnedXp = 0;
            player.level++;
            player.nextLevelXp = calculateRequiredXp(player.level);
            player.attackDamage += calculateAdIncrease(player.level);
            player.hp = player.maxHp;
            console.log("Character Level UP. New Level: %s", player.level);
        } else {
            player.earnedXp += _amount;
            console.log("Character earned %s XP, %s XP required for next level", player.earnedXp, (player.nextLevelXp-player.earnedXp));
        }
    }

    function calculateRequiredXp(uint256 _currentLevel) public pure returns(uint256){
        return _currentLevel*10;
    }

    function calculateAdIncrease(uint256 _newLevel) public pure returns (uint256) {
        return 2**_newLevel;
    }
}
