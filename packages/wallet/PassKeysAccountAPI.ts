import {
    BaseAccountAPI, BaseApiParams
} from '@account-abstraction/sdk/dist/src/BaseAccountAPI'
import { UserOperationStruct } from '@account-abstraction/contracts'
import { BigNumber, BigNumberish } from 'ethers'
import { defaultAbiCoder, arrayify, hexConcat } from 'ethers/lib/utils'
import { 
    PassKeysAccount, PassKeysAccount__factory,
    PassKeysAccountFactory, PassKeysAccountFactory__factory
} from '../../typechain-types'
import { PassKeyKeyPair } from './WebAuthnWrapper'

export interface PassKeysAccountApiParams extends BaseApiParams {
    factoryAddress: string
    index: BigNumber
    passKeyPair: PassKeyKeyPair
}
export class PassKeysAccountApi extends BaseAccountAPI {
    factoryAddress: string
    index: BigNumber
    passKeyPair: PassKeyKeyPair
    accountContract?: PassKeysAccount
    factoryContract?: PassKeysAccountFactory

    constructor(params: PassKeysAccountApiParams) {
        super(params)
        this.factoryAddress = params.factoryAddress
        this.index = params.index ?? BigNumber.from(0)
        this.passKeyPair = params.passKeyPair
    }

    async _getAccountContract(): Promise<PassKeysAccount> {
        if (!this.accountContract) {
            this.accountContract = PassKeysAccount__factory.connect(await this.getAccountAddress(), this.provider)
        }
        return this.accountContract
    }

    async getAccountInitCode(): Promise<string> {
        if (this.factoryContract == null) {
            if (this.factoryAddress != null && this.factoryAddress !== '') {
                this.factoryContract = PassKeysAccountFactory__factory.connect(this.factoryAddress, this.provider)
            } else {
                throw new Error('factoryAddress is not set')
            }
        }
        return hexConcat([
            this.factoryContract.address,
            this.factoryContract.interface.encodeFunctionData("createAccount", [
                this.index, 
                this.passKeyPair.keyId, 
                this.passKeyPair.pubKeyX, 
                this.passKeyPair.pubKeyY
            ])
        ])
    }

    async getNonce (): Promise<BigNumber> {
        if (await this.checkAccountPhantom()) {
          return BigNumber.from(0)
        }
        const accountContract = await this._getAccountContract()
        return await accountContract.nonce()
    }

    async encodeExecute (target: string, value: BigNumberish, data: string): Promise<string> {
        const accountContract = await this._getAccountContract()
        return accountContract.interface.encodeFunctionData(
          'execute',
          [
            target,
            value,
            data
          ])
      }
    
    async signUserOpHash(userOpHash: string): Promise<string> {
        let sig = await this.passKeyPair.signChallenge(userOpHash)
        let encodedSig = defaultAbiCoder.encode(['bytes32', 'uint256', 'uint256', 'bytes', 'string', 'string'], [
            sig.id,
            sig.r,
            sig.s,
            sig.authData,
            sig.clientDataPrefix,
            sig.clientDataSuffix
        ])
        return encodedSig
    }    

    /**
     * return maximum gas used for verification.
     * NOTE: createUnsignedUserOp will add to this value the cost of creation, if the contract is not yet created.
     */
    async getVerificationGasLimit (): Promise<BigNumberish> {
        return 1000000
    }

    /**
     * should cover cost of putting calldata on-chain, and some overhead.
     * actual overhead depends on the expected bundle size
     */
    async getPreVerificationGas (userOp: Partial<UserOperationStruct>): Promise<number> {
        const estimate = await super.getPreVerificationGas(userOp)
        return estimate*100
    }    
    /**
     * Sign the filled userOp.
     * @param userOp the UserOperation to sign (with signature field ignored)
     */
    async signUserOp (userOp: UserOperationStruct): Promise<UserOperationStruct> {
        console.log("Signing UserOp", userOp)
        const userOpHash = await this.getUserOpHash(userOp)
        const signature = await this.signUserOpHash(userOpHash)
        return {
            ...userOp,
            signature
        }
    }

}
