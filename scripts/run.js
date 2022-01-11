const main = async () => {
    const gameContractFactory = await hre.ethers.getContractFactory('MyEpicGame');
    const gameContract = await gameContractFactory.deploy(
        ["Harmony", "Ron", "Harry"],       // Names
        ["https://i.ibb.co/wCfYGqk/Screen-Shot-2022-01-07-at-04-08-53.png", // Images
            "https://i.ibb.co/NpTHhmF/Screen-Shot-2022-01-07-at-04-09-09.png",
            "https://i.ibb.co/YTgMBqZ/Screen-Shot-2022-01-07-at-04-09-04.png"],
        [500, 500, 500],                    // HP values
        [50, 100, 50]                       // Attack damage values
    );
    await gameContract.deployed();
    console.log("Contract deployed to:", gameContract.address);
    let txn;
    // We only have three characters.
    // an NFT w/ the character at index 2 of our array.
    txn = await gameContract.mintCharacterNFT(2);
    await txn.wait();

    // Get the value of the NFT's URI.
    let returnedTokenUri = await gameContract.tokenURI(1);
    console.log("Token URI:", returnedTokenUri);

};

const runMain = async () => {
    try {
        await main();
        process.exit(0);
    } catch (error) {
        console.log(error);
        process.exit(1);
    }
};

runMain();




  // https://i.ibb.co/F8xq6rH/Voldemort-Headshot-DHP1.png