import { utils, parsers } from '@passwordless-id/webauthn'
import { AuthenticationEncoded, RegistrationEncoded } from '@passwordless-id/webauthn/dist/esm/types'
import { BigNumber } from 'ethers'
import { arrayify } from 'ethers/lib/utils'
import { WebAuthnUtils } from './utils/WebAuthnUtils'
import base64url from 'base64url';

export interface IWebAuthnClient {
    register(challenge:string, name?:string): Promise<RegistrationEncoded>
    authenticate(challenge: string, keyid?: string): Promise<AuthenticationEncoded>
}

export interface PassKeySignature {
    id: BigNumber
    r: BigNumber
    s: BigNumber
    authData: Uint8Array
    clientDataPrefix: string
    clientDataSuffix: string
}

export class PassKeyKeyPair {
    rawId: BigNumber
    pubKeyX: BigNumber
    pubKeyY: BigNumber
    keyId: string
    webAuthnClient: IWebAuthnClient

    constructor(keyId: string, pubKeyX: BigNumber, pubKeyY: BigNumber, webAuthnClient: IWebAuthnClient) {
        this.rawId = BigNumber.from(base64url.toBuffer(keyId))
        this.pubKeyX = pubKeyX
        this.pubKeyY = pubKeyY
        this.webAuthnClient = webAuthnClient
        this.keyId = keyId
    }

    async signChallenge(payload: string): Promise<PassKeySignature> {
        // ophash is a keccak256 hash of the user operation as a hex string
        // this needs to be base64url encoded from raw bytes of the hash
        const challenge = utils.toBase64url(arrayify(payload)).replace(/=/g, '')

        const authData = await this.webAuthnClient.authenticate(challenge, this.keyId)
        let sig = WebAuthnUtils.getMessageSignature(authData.signature)
        let clientDataJSON = new TextDecoder().decode(utils.parseBase64url(authData.clientData))
        let challengePos = clientDataJSON.indexOf(challenge)
        let challengePrefix = clientDataJSON.substring(0, challengePos)
        let challengeSuffix = clientDataJSON.substring(challengePos + challenge.length)
        let authenticatorData = new Uint8Array(utils.parseBase64url(authData.authenticatorData))
        return {
            id: this.rawId,
            r: sig[0],
            s: sig[1],
            authData: authenticatorData,
            clientDataPrefix: challengePrefix,
            clientDataSuffix: challengeSuffix
        }
    }
}

export class WebAuthnWrapper {
    webAuthnClient: IWebAuthnClient

    constructor(webAuthnClient: IWebAuthnClient) {
        this.webAuthnClient = webAuthnClient
    }

    public async registerPassKey(payload: string, name?:string): Promise<PassKeyKeyPair> {
        const regData = await this.webAuthnClient.register(payload, name);
        const parsedData = parsers.parseRegistration(regData);
        let pkey = await WebAuthnUtils.getPublicKeyFromBytes(parsedData.credential.publicKey);
        return new PassKeyKeyPair(parsedData.credential.id, pkey[0], pkey[1], this.webAuthnClient);
    }
}
