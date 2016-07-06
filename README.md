# Databox App Server
A Databox Docker registry front-end, an instance of which is running at http://datashop.amar.io/.

## Installation
	git clone https://github.com/yousefamar/databox-app-server.git
	cd databox-app-server
	npm install --production

## Usage
Add API keys to `config-template.json` and save it as `config.json`. Then run server with:

	npm start

Default port is 8080, but can be overridden using the PORT environment variable, i.e.:

	PORT=8081 npm start

## API Endpoints

All accept form-encoded POST or GET parameters and return JSON.

Warning: This is very much a work in progress and subject to backwards-incompatible change.

### /app/post

Posts app metadata (requires login)

#### Parameters:
  - manifest (An app manifest.json string - see /app/list for specs)

#### Response:
  - error:
    - 22 (Poster not logged in)
    - 21 (Missing or illegal data) - may be expanded into multiple error codes
    - TBC
  - success: true

### /app/get

Gets app metadata (does not require login)

#### Parameters:
  - name (Name of the app to query)

#### Response:
  - error:
    - 23 (App not found)
    - TBC
  - App metadata DB entry (see /app/list)


### /app/list

List all app metadata. Each app metadata object consists of:

  - manifest: (Parsed app manifest)
    - manifest-version: [Number]
    - name: [String] \(one unique word)
    - version: [String] \([semver](http://semver.org/))
    - description: [String] \(single line description)
    - author: [[Person](https://docs.npmjs.com/files/package.json#people-fields-author-contributors)]
    - license: [[License](https://docs.npmjs.com/files/package.json#license)]
    - tags: [Array of strings]
    - homepage: [String]
    - repository: [[Repository](https://docs.npmjs.com/files/package.json#repository)]
    - requirements: [Array of Strings] \(A list of data sources the app requires access to (lower bound))
    - optional-requirements: [Array of Strings] \(A list of data sources the app requires access to (upper bound))
    - (resource-requirements: [Object] \(Hardware resources the app requires (lower bound)))
    - TBC
  - poster:
    - id: [Databse user ID]
    - username: [username]
    - TBC
  - postDate: [Unix timestamp of post date]
  - queries: [Number of times queried]
  - (verified: [If app has passed screening - should hide from or warn user if not]) - WIP; could be "state" or other info too or hash externally verifed etc.

#### Response:
  - apps: [Array of app metadata in natural order]


### /user/register

Registers a user; adds info to DB and marks as unverified until email confirmed.

#### Parameters:
  - username
  - email
  - password
  - recaptcha (Value of `g-recaptcha-response`)

#### Response:
  - error:
    - 11 (One or more empty fields)
    - 12 (Email taken)
    - 13 (Username taken)
    - 16 (No reCAPTCHA)
    - 17 (Bad reCAPTCHA)
    - TBC
  - success: true

### /user/login

Logs a user in (session cookie).

#### Parameters:
  - username or email
  - password

#### Response:
  - error:
    - 11 (One or more empty fields)
    - 14 (Email or username incorrect) - may be combined with 15 in future
    - 15 (Password incorrect) - may be combined with 14 in future
  - success: true

### /user/whoami

Debug endpoint for checking if logged in.

#### Response:
  - id:
    - [user ID]
    - null (if not logged in)

### /user/whois

Translates database user ID to username.

#### Parameters:
  - _id

#### Response:
  - error:
    - 31 (Missing profile)
  - _id: [database UID]
  - username: [username]

### /user/logout

Destroys session

#### Response:
  - err: [Error object]
  - success: true

### /user/verify

Verifies a user's email address (GET recommended; link sent in verification email).

NB: Will 302 redirect to root domain on successful verification.

NB: Will 302 redirect to root domain if parameters are missing instead of responding with an error.

#### Parameters:
  - email
  - hash

#### Response:
  - error: (temporary)
    - 18 (Invalid email verification link)
