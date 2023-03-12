import { RegistrationEncoded, AuthenticationEncoded, RegisterOptions, AuthenticateOptions } from "@passwordless-id/webauthn/dist/esm/types";
import { IWebAuthnClient} from "../WebAuthnWrapper";
import {client, utils} from "@passwordless-id/webauthn"

export class WebAuthnPlugin implements IWebAuthnClient {
    async register(challenge: string, name?:string, options?:RegisterOptions): Promise<RegistrationEncoded> {
        return client.register(name? name : utils.randomChallenge(), challenge, options);
    }
    async authenticate(challenge: string, keyid?: string | undefined, options?: AuthenticateOptions): Promise<AuthenticationEncoded> {
        return client.authenticate(keyid? [keyid] : [], challenge, options);
    }
}