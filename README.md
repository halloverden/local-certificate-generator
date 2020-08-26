# Certificate Generator
This project provides a way to generate a root certificate, and to sign certificates using the generated root certificate. The certificates should only be used for local development projects. For production sites, use a proper CA, trusted by browsers, for example [Let's Encrypt](https://letsencrypt.org).

## Usage
* Copy the `generator.conf.dist` file to `generator.conf`, and fill it with data relevant to your use case.
* Run the `root-certificate-generator.sh`, and provide the information asked for.
  * The generated root certificate files can be stored somewhere safe for later use, in case you need to sign certificates for several projects.
* Run the `certificate-signer.sh`, and provide the information asked for.

All generated files will, by default, be stored in the `src/generated` folder, and they are ignored by the `.gitignore` file. The location can be changed in the config file.

## Pro tip
The root certificate requires a password. You should store the root certificate files, and the password in a safe place, even if the only use is for local development projects. Some password managers support the storage of both passwords and certificates.
