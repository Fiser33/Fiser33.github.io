---
title: "Share certificate using Fastlane/Match"
categories: CI/CD
---

If you ever worked on an iOS project in a team, I bet you had to deal with certificates sharing. It is not as important with developer certificates as every developer can create their own. But we can't do that for distribution certificates as there is a limitation only up to 3 can exist at the time on Apple Developer Account.

Even though this can be done manually among the developers (because not everyone needs access to distribution certificate in the end) it comes very handy when you automate the process and it is almost a must if you use any CI/CD automation.

Let me show you how to setup and share the certificates using a quite common automation tool - [Fastlane](https://fastlane.tools).

# Fastlane/Match

If you're not familiar with Fastlane yet, it is an open source command line tool for mobile developers written in Ruby. Fastlane can help you to focus just on coding as it can be used for example to update app version, run tests, generate screenshots, manage code signing and deploy your application.

We'll be most interested in code signing management today. There is a special module called **Match** just for that. It communicates with App Store Connect via API (to create or fetch certificates/profiles) but can also be helpful when it comes to storing and sharing them with the team.

As Fastlane is available as Ruby Gem, I personally prefer to install it using [Bundler](https://bundler.io). If you have installed Fastlane any other way, just ignore `bundle exec` prefix in all bash commands here.

# Prepare git branch

Match supports multiple types of storage - git repository, Google Cloud and Amazon S3. We'll go with git repository for simplicity.

Usually, you would have a separate private repository just to share the certificates and provisioning profiles with the team. For demo purpose, we'll create an orphan branch instead in existing project repository. In the end, it behaves the same as completely new git repository. It may also be easier for you if you only want to see Match in action.

Here's how you can create new orphan branch in your existing project:

```bash
git checkout --orphan fastlane_match

git rm -rf .
rm -rf *

git commit --allow-empty -m "New branch for Fastlane Match"
git push --set-upstream origin fastlane_match
```

The code creates new orphan branch, removes all existing code from the directory to start empty and pushes the new branch to git.

Now with empty branch available, you can checkout back to your development branch to run Fastlane in next steps.

# Match configuration

To let Match know where to search for certificates (and provisioning profiles), you should include the configuration file *Matchfile* in you project (usually located in fastlane directory).

The minimum content should be:

```
git_url("<GIT_REPOSITORY_URL>")
git_branch("fastlane_match")
type("appstore")    # Supported values are: appstore, adhoc, development, enterprise, developer_id, mac_installer_distribution
app_identifier("<APP_BUNDLE_IDENTIFIER>")
```

There are of course more configuration options, for example to clone specified branch directly, specify team ID in case you have access to more than one, and more. You can find full list of configuration options in official [documentation](https://docs.fastlane.tools/actions/match/) to Match.

Matchfile also needs to be commited to the project repository so everyone can run Match to fetch the certificates (and provisioning profiles).

# Prepare certificate

Now let's prepare the certificate for import to Match. Regardless if you already have any certificate created, you need to end up with *.cer* and *.p12* files in your directory.

## Generate new certificate

If you don't have any certificate created yet (or want to create new one anyway), you can generate new one using Fastlane tool like this:

```bash
bundle exec fastlane cert -u "<YOUR_APPLE_ID>"
```

This generates distribution certificate by default, you can change that by adding `--development` option. If you already have a certificate but you want to generate new one (for example if the existing one is about to expire soon), you can use `--force` option.

Newly generated certificate files are now located in your working directory. Do not change their name as the name matches the certificate identifier by which fastlane looks them up later on.

## Use existing certificate

If you already have an existing certificate imported in your Keychain, you can right click on it and export it both as *.cer* and *.p12* files.

The only tricky part here may be finding out the certificate identifier to propely name exported files. The easiest solution may be to run the same command as for generating new certificate, but this time with `--readonly` option. This should fetch only *.cer* file in your working directory with proper name.

# Upload

Assuming you have prepared both empty git branch and certificate files, we can finally move on to upload the certificate to git using Match. For that, just use following command:

```bash
bundle exec fastlane match import
```

The import command is interactive and Match will prompt you for following information:

* Path to *.cer* file - You will have to provide full path (without ~).
* Path to *.p12* file - Similar to .cer path.
* Path to provisioining profile (*.mobileprovision* or *.provisionprofile*) - You can leave this empty if you don't have any yet.
* Passphrase to Match storage - This is an encryption password to apply on files in git repository. You can inject this value as environment value *MATCH_PASSWORD*.
* App Store Connect credentials - Match runs some checks against App Store Connect to see if provided certificate is valid. You can inject the value by providing [api\_key.json](https://docs.fastlane.tools/app-store-connect-api/) file with `--api_key_path PATH` option or as environment value *SIGH_API_KEY_PATH*.

Done! You can check that the specified repository and branch now contains your certificate. To share it among other developers, all they need to do is to run `bundle exec fastlane match` in the project directory (as soon as *Matchfile* configuration is available to them) and they're good to go.

# Conclusion

By following steps above you should have successfully uploaded your certificate to a git repository. From there, any developer in your team should be able to fetch and use the shared certificate with minimal effort.

The biggest impact you'll notice is when it comes to CI/CD automated build, when new developer joins the team or when the certificate expires and new one needs to be distributed to the team again.