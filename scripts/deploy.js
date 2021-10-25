const main = async () => {
  const gameContractFactory = await hre.ethers.getContractFactory("MyEpicGame");
  const gameContract = await gameContractFactory.deploy(
    ["Tanjiro", "Jigglypuff", "Kirby"],
    [
      "https://imgur.com/dghTs8A.png",
      "https://imgur.com/8vViXiW.png",
      "https://i.imgur.com/71AKCZZ.png",
    ],
    [300, 200, 125],
    [100, 50, 150],
    "Herbert Hoover",
    "https://i.imgur.com/kOyM0Yc.jpg",
    10000,
    50
  );
  await gameContract.deployed();
  console.log("Contract deployed to:", gameContract.address);

  // let txn;
  // txn = await gameContract.mintCharacterNFT(2);
  // await txn.wait();

  // // Attack the boss
  // txn = await gameContract.attackBoss();
  // await txn.wait();

  // txn = await gameContract.attackBoss();
  // await txn.wait();

  console.log("Complete.");
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
