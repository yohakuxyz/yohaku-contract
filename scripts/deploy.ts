import { ethers } from "hardhat";

const dev2: string = "0x06aa005386f53ba7b980c61e0d067cabc7602a62";
async function main() {
  const NFTFactory = await ethers.getContractFactory("NFTFactory");
  const factory = await NFTFactory.deploy();
  await factory.waitForDeployment();

  console.log(`NFTFactory deployed to ${factory.target}`);

  const SkyBlueFactory = await ethers.getContractFactory("SkyBlue");
  const skyblue = await SkyBlueFactory.deploy(
    dev2,
    "ipfs://bafkreidp6xswfzex5mr6akr7azn3e4rza57ukuxyo2tq6slymliaeuenoi"
  );
  console.log("SkyBlue deployed to:", skyblue.target);

  const RegistryFactory = await ethers.getContractFactory("Registry");
  const registry = await RegistryFactory.deploy();

  console.log("Registry deployed to:", registry.target);
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
// npx hardhat run scripts/deploy.ts --network polygonMumbai 0x772dD39407A804dA53744d3fAB8445bC09d54295 0x06aa005386f53ba7b980c61e0d067cabc7602a62 ipfs://bafkreidp6xswfzex5mr6akr7azn3e4rza57ukuxyo2tq6slymliaeuenoi
