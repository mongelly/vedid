import * as Yargs from 'yargs';
import * as fileIO from 'fs';
import path from 'path';
import * as ReadlineSync from 'readline-sync';
import { Keystore, address, secp256k1 } from 'thor-devkit';
import { Driver, SimpleNet, SimpleWallet } from '@vechain/connex-driver';
import { Framework } from '@vechain/connex-framework';
import { compileContract } from 'myvetools/dist/utils';
import { Contract } from 'myvetools';
import { getReceipt } from 'myvetools/dist/connexUtils';

const argv = Yargs.scriptName('tools')
  .usage('<cmd> [args]')
  .command('node [args]', '', (yargs) => {
    yargs.positional('config', {
      alias: 'c',
      type: 'string',
      default: ''
    });
    yargs.positional('keystore', {
      alias: 'k',
      type: 'string',
      default: ''
    });
  }).help().argv;

  const environment: any = {};
  environment.contracts = new Map<string,Contract>;

  async function run(argv: any) {
    initEnv(argv);
    await initBlockChain(argv);

    console.info(`
    ********************  VeChain Asset Bridge Tools Info ********************
    | VeChain Node Info    | Host: ${environment.config.nodeHost}  ChainId: ${environment.config.chainId} 
    | Key Address      | ${environment.master}
    *******************************************************************
    `);
    await operations();
  }

  function initEnv(argv: any) {
    var configPath = (argv.config || "" as string).trim();
    if (fileIO.existsSync(configPath)) {
      try {
        const config = require(configPath);
        environment.config = config;
        environment.configPath = configPath;
      } catch (error) {
        console.error(`Read config faild,error:${error}`);
        process.exit();
      }
    } else {
      console.error(`Can't load configfile ${configPath}`);
      process.exit();
    }
  }

  async function initBlockChain(argv: any) {
    environment.contractdir = path.join(__dirname, "../../../contracts/");
    const prikey = await loadNodeKey(argv);
    await initConnex(prikey);
    await initContracts();
  }

  async function initContracts() {
    contractInstance("DID","DIDHub.sol");
    contractInstance("DIDManager","DIDManager.sol");
    contractInstance("ControllerManager","ControllerManager.sol");
    contractInstance("VerificationManager","VerificationManager.sol");
  }

  async function loadNodeKey(argv: any): Promise<string> {
    const keystorePath = (argv.keystore || "" as string).trim();
    if (fileIO.existsSync(keystorePath)) {
        try {
            const ks = JSON.parse(fileIO.readFileSync(keystorePath, "utf8"));
            const pwd = ReadlineSync.question(`keystore password:`, { hideEchoBack: true });
            const prikey = await Keystore.decrypt((ks as any), pwd);
            const pubKey = secp256k1.derivePublicKey(prikey);
            const addr = address.fromPublicKey(pubKey);
            environment.master = addr;
            return prikey.toString('hex');
          } catch (error) {
            console.error(`Keystore or password invalid. ${error}`);
            process.exit();
          }
    } else {
        console.error(`Can't load node key`);
        process.exit();
    }
  }

  async function initConnex(priKey: string) {
    try {
      const wallet = new SimpleWallet();
      wallet.import(priKey);
      environment.wallet = wallet;
      const driver = await Driver.connect(new SimpleNet(environment.config.nodeHost as string), environment.wallet);
      environment.connex = new Framework(driver);
      const geneisiBlock = await (environment.connex as Framework).thor.block(0).get();
      environment.config.chainId = geneisiBlock?.id.substring(64);
    } catch (error) {
      console.error(`Init connex faild`);
      process.exit();
    }
  }

  async function operations() {
    const operations = [
      'DID Info',
      'Deploy DIDHub',
      'Deploy and register DIDManager ',
      'Deploy and register ControllerManager ',
      'Deploy and register VerificationManager',
      'Deploy and register Method_VerifySender',
      'Deploy and register Method_ECDSA',
      'Register New DID'
    ];
    while(true){
      const index = ReadlineSync.keyInSelect(operations, 'Which Operation?');
      switch (index) {
        case -1:
          console.info('Quit Tools');
          process.exit();
        case 0:
          await didInfo();
          break;
        case 1:
          await deployDIDHub();
          break;
        case 2:
          await deployDIDManager();
          break;
        case 3:
          await deployControllerManager();
          break;
        case 4:
          await deployVerificationManager();
          break;
        case 5:
          await deployVerifySender();
          break;
        case 6:
          await deployECDSA();
          break;
        case 7:
          await registerDID();
      }
    }
  }

  async function didInfo() {
    const operations = [
      'DID Hub list'
    ];
    while(true){
      const index = ReadlineSync.keyInSelect(operations, 'Which Operation?');
      switch (index) {
        case -1:
          return;
        case 0:
          break;
      }
    }
  } 

  async function deployDIDHub() {
    try {
      console.info('--> Step1/1: Deploy DIDHub contract.')
      const didHub = (environment.contracts as Map<string,Contract>).get("DID")!;
      const clause = didHub.deploy(0,"vedid");
      const txrep = await (environment.connex as Framework).vendor.sign('tx', [clause]).signer(environment.master).request();
      const receipt = await getReceipt(environment.connex, 6, txrep.txid);
      if (receipt == null || receipt.reverted || receipt.outputs[0].contractAddress == undefined) {
        console.error(`Deploy DIDHub faild, txid: ${receipt.meta.txID}`);
        return;
      }
      didHub.at(receipt.outputs[0].contractAddress);
      environment.config.contracts.didhub = didHub.address;
      fileIO.writeFileSync(environment.configPath, JSON.stringify(environment.config, null, 4));
      console.info(`Deploy DIDHub success. address: ${receipt.outputs[0].contractAddress} txid: ${receipt.meta.txID} blockId: ${receipt.meta.blockID}`);
    } catch (error) {
      console.error(`Deploy DIDHub contracts faild. error: ${error}`);
      return;
    }
  }

  async function deployDIDManager() {
    try {
      checkDIDHUb();
      const didHub = (environment.contracts as Map<string,Contract>).get("DID")!;
      const didManager = (environment.contracts as Map<string,Contract>).get("DIDManager")!;

      console.info('--> Step1/2: Deploy DIDManager contract.')
      const clause1 = didManager.deploy(0,didHub.address);
      const rep1 = await (environment.connex as Framework).vendor.sign('tx', [clause1]).signer(environment.master).request();
      const recp1 = await getReceipt(environment.connex, 6, rep1.txid);
      if (recp1 == null || recp1.reverted || recp1.outputs[0].contractAddress == undefined) {
        console.error(`Deploy DIDManager faild, txid: ${recp1.meta.txID}`);
        return;
      }
      
      console.info('--> Step2/2: Register DIDManager to DIDHub.');
      const clause2 = didHub.send('setHub',0,nameToHubId("DIDManager"),recp1.outputs[0].contractAddress);
      const rep2 = await (environment.connex as Framework).vendor.sign('tx', [clause2]).signer(environment.master).request();
      const recp2 = await getReceipt(environment.connex, 6, rep2.txid);
      if (recp2 == null || recp2.reverted || recp2.outputs[0].contractAddress == undefined) {
        console.error(`Deploy DIDManager faild, txid: ${recp1.meta.txID}`);
        return;
      }
      didManager.at(recp1.outputs[0].contractAddress);
    } catch (error) {
      console.error(`Deploy DIDManager contracts faild. error: ${error}`);
      return;
    }
  }

  async function deployControllerManager() {
    try {
      checkDIDHUb();
      const didHub = environment.contracts.didhub as Contract;
      const didManager = environment.contracts.didManager as Contract;

      console.info('--> Step1/2: Deploy DIDManager contract.')
      const clause1 = didManager.deploy(0,didHub.address);
      const rep1 = await (environment.connex as Framework).vendor.sign('tx', [clause1]).signer(environment.master).request();
      const recp1 = await getReceipt(environment.connex, 6, rep1.txid);
      if (recp1 == null || recp1.reverted || recp1.outputs[0].contractAddress == undefined) {
        console.error(`Deploy DIDManager faild, txid: ${recp1.meta.txID}`);
        return;
      }
      didManager.at(recp1.outputs[0].contractAddress);
      
      console.info('--> Step2/2: Register DIDManager to DIDHub.');
      const clause2 = didHub.send('setHub',0,nameToHubId("DIDManager"),didManager.address);
      const rep2 = await (environment.connex as Framework).vendor.sign('tx', [clause2]).signer(environment.master).request();
      const recp2 = await getReceipt(environment.connex, 6, rep2.txid);
      if (recp2 == null || recp2.reverted || recp2.outputs[0].contractAddress == undefined) {
        console.error(`Deploy DIDManager faild, txid: ${recp1.meta.txID}`);
        return;
      }
      environment.config.contracts.didManager = didManager.address;
    } catch (error) {
      console.error(`Deploy DIDManager contracts faild. error: ${error}`);
      return;
    }
  }

  async function deployVerificationManager() {

  }

  async function deployVerifySender() {

  }

  async function deployECDSA() {

  }

  async function registerDID() {

  }

  function checkDIDHUb() {
    if(environment.config.contracts.didhub == undefined || (environment.config.contracts.didhub as string).length != 42){
      const value = ReadlineSync.question('Enter the DIDHub contract address').trim().toLowerCase();
      environment.config.contracts.didhub = value;
    }
  }

  function nameToHubId(name:string):string {
    return '0x' + Buffer.from('name','utf8').toString('hex').padEnd(64,'0');
  }

  function contractInstance(name:string,filename:string) {
    const file = path.join( path.join(environment.contractdir,filename));
    const abi = JSON.parse(compileContract(file,name,"abi",[environment.contractdir]));
    const bin = compileContract(file,name,"bytecode",[environment.contractdir]);
    const contract = new Contract({connex:environment.connex,abi:abi,bytecode:bin});
    (environment.contracts as Map<string,Contract>).set(name,contract);
  }

  run(argv);