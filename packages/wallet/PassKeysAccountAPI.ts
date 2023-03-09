import {
    BaseAccountAPI, BaseApiParams
} from '@account-abstraction/sdk/dist/src/BaseAccountAPI'
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
                this.passKeyPair.rawId, [
                    this.passKeyPair.pubKeyX, 
                    this.passKeyPair.pubKeyY
                ]
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
        return defaultAbiCoder.encode(['uint256', 'uint256', 'uint256', 'bytes', 'string', 'string'], [
            sig.id,
            sig.r,
            sig.s,
            sig.authData,
            sig.clientDataPrefix,
            sig.clientDataSuffix
        ])
      }    
}
