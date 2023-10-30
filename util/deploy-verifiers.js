const fs = require('fs');
const { ethers } = require('hardhat');

async function deployAgg() {}
async function deploySig() {}

async function main() {
  const raw = fs.readFileSync('script/output/deployed_lgr.json');
  const json = JSON.parse(raw);
  const addresses = json.addresses;

  const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL);
  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

  // deploy - single signature

  let triageABIraw = fs.readFileSync(
    'out/SlashingSingleVerifierTriage.sol/SlashingSingleVerifierTriage.json',
  );
  let triageABIjson = JSON.parse(triageABIraw);
  let triageABI = triageABIjson.abi;
  let triage = new ethers.Contract(addresses['SigVerify'], triageABI, wallet);

  // deploy
  path = 'src/library/slashing_single/verifier.sol:Verifier';
  factory = await ethers.getContractFactory(path);
  verifier = await factory.deploy();
  tx = await verifier.deployed();
  console.log(
    'slashing_single verifier contract deployed to address',
    verifier.address,
  );

  // associate
  tx = await triage.setRoute(1, verifier.address);
  console.log(
    'verifier contract associated with triage contract at',
    triage.address,
  );
  await tx.wait();

  // deploy - aggregate

  triageABIraw = fs.readFileSync(
    'out/SlashingAggregate16VerifierTriage.sol/SlashingAggregate16VerifierTriage.json',
  );
  triageABIjson = JSON.parse(triageABIraw);
  triageABI = triageABIjson.abi;
  triage = new ethers.Contract(addresses['AggVerify'], triageABI, wallet);

  const sizes = [16, 32, 64];
  for (size of sizes) {
    // deploy
    path = `src/library/slashing_aggregate_${size}/verifier.sol:Verifier`;
    factory = await ethers.getContractFactory(path);
    verifier = await factory.deploy();
    tx = await verifier.deployed();
    console.log(
      'slashing_aggregate verifier contract for size',
      size,
      'deployed to address',
      verifier.address,
    );

    // associate
    tx = await triage.setRoute(size, verifier.address);
    console.log(
      'verifier contract associated with triage contract at',
      triage.address,
    );
    await tx.wait();
  }
}

main();
