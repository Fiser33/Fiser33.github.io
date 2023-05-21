---
title: "Application secrets"
categories: Technical
---

# Intro
As developers, our responsibility is not only to create an appealing user interface and communicate with a server. We are also responsible for setting up an automation or making the application accessible. And last but not least, we must make sure that the application is secured. Not only to protect user data but also to protect application resources.

A key aspect to that are application secrets. I would like to focus on two security risks - storing secrets in git repository and having them easily extractable from the application IPA file. 

You may argue that those are not significant risks as it is difficult to get to a private git repository or to download an IPA file. That's probably right, I must admit that I don't have much experience in that area. However I still believe it is not really impossible.

Let's have a look on how developers can manage application secrets and what potential risks there are for each possibility.

I have prepared a demonstration project in [this repository](https://github.com/Fiser33/Fiser33.github.io/tree/main/examples/technical/app_secrets) that demonstrates every option here. All code examples and CLI commands below will refer to this project so feel free to download to follow along.

# Source code
One of the easiest ways for developers is to have the key directly in code. This way the key is stored directly next to the code where it is used. This is for sure the fastest option to set up and you can also use compilation flags to provide different values per Configuration. Here's an example of a possible implementation:

```
class SourceCode {
  let apiKey = "abcdefgh-ijkl-mnop-qrst-uvwxyz12"
}
```

An obvious issue here is that anyone with access to a repository can read it there. Even when you remove it in a later commit as the value may still remain in git history.

Another issue is that if someone gets your application' IPA file, they can extract all hardcoded strings quite easily using pre-installed tools on macOS. To try, just create an archive in your project. Then navigate in Terminal to the archive directory and run following code:

```
strings *.xcarchive/Products/Applications/AppSecrets.app/AppSecrets | grep -i "abcdefgh-ijkl-mnop-qrst-uvwxyz12"
```

While the list of strings will be pretty long even for small projects, this still proves that a secret will be there. Plus the list is available using a pre-installed tool, imagine what third party tools could do.

## Summary
Pros:
- No overhead on developers

Cons:
- Will be stored on git as a plain text
- Can be easily extracted from IPA file

# Info.plist
Ok, storing secrets in source code directly did not prove to be very safe. Another option is to have them in an **Info.plist** file. This file mostly contains application metadata and can be used as a bridge from project settings to application runtime. Values defined here will no longer be there in list of strings. Just add the following to define a custom value:

```
<key>API_KEY_1</key>
<string>abcdefgh-ijkl-mnop-qrst-uvwxyz12</string>
```

You use standard `Bundle` object to access that value. The downside here is that the value is optional so one does need to handle them properly, according to the context.

```
class ApiService {
  let apiKey = Bundle.main.infoDictionary?["API_KEY_1"] as? String
}
```

So a secret is no longer directly stored in source code and therefore not accessible in that list of application strings. On the other hand, **Info.plist** file is still just a plain text. Moreover, it is there to easily read in application archive. Just create an archive and in the output directory see content of file `*.xcarchive/Products/Applications/AppSecrets.app/Info.plist`.

## Summary
Pros:
- Minimal overhead on developers
- Not visible by `strings` command

Cons:
- Will be stored on git as a plain text
- Can be easily extracted from IPA file
- Need to handle optionals

# Build settings
So far it seems that using **Info.plist** file is not very beneficial. But let's not go away from it yet. There are certain improvements we can apply. Instead of having secrets in **Info.plist** file directly, they can be read from the Build Settings with possibility to define custom values as User-Defined Setting.

To create a new User-Defined value, navigate to the project settings (1), make sure you have selected correct Target (2), then go to Build Settings tab (3) and hit Plus button on top left to Add User-Defined Setting (4). For the demo project, I have created a key **API_KEY_2** with the same value as in previous examples. 

![Build Settings](/assets/images/app_secrets_build_settings.png)
*Build Settings of the demo project.*

Once done, you make the value available through **Info.plist** file by using the User-Defined Setting name as follows:

```
<key>API_KEY_2</key>
<string>$(API_KEY_2)</string>
```

This approach has all the benefits and disadvantages as with having the key in **Info.plist** directly. However, there is a difference that you can now easily use different value per project Configuration. That means you can have different values for Debug and Release versions.

## Summary
Pros:
- Minimal overhead on developers
- Secrets can differ per Configuration

Cons:
- Will be store on git as a plain text
- Can be easily extracted from IPA file
- Need to handle optionals

# Configuration Settings File
With all the previous options, app secrets are still stored in the repository as a plain text. Luckily, this can be resolved by creating a Configuration Settings File (xcconfig). It is basically a list of Build Settings, including custom User-Defined Settings, extracted to a separate file.

To create a new xcconfig file, add a New File to the project and select Configuration Settings File. If you need to provide different values for each configuration, just create multiple xcconfig files, for example `Debug.xcconfig` and `Release.xcconfig`.

![Add new Configuration Settings File](/assets/images/app_secrets_xcconfig_1.png)
*Select Configuration Settings File from the New File options.*

For the demonstration project, we provide our secret as follows. Additional to that, you might need to add *PRODUCT_BUNDLE_IDENTIFIER* and *DEVELOPMENT_TEAM* values.

```
API_KEY_3 = abcdefgh-ijkl-mnop-qrst-uvwxyz12
```

When created, you need to go to your project settings (1, 2) and assign these configuration files to each project Configuration (3).

![Assign Configuration Settings File](/assets/images/app_secrets_xcconfig_2.png)
*Assign Configuration Settings Files to project configurations.*

As a result, your app secrets can be kept out of your git repository by including `*.xcconfig` files in `.gitignore`. Other than that, there's no difference from the previous approach.

## Summary
Pros:
- Secrets not stored on git
- Secrets can differ per Configuration

Cons:
- Can be easily extracted from IPA file
- Need to handle optionals
- Extra effort on new project members onboarding

# Third party frameworks
As there are no other native options, we need to explore third party solutions now. There is a popular framework [cocoapods-keys](https://github.com/orta/cocoapods-keys) that generates Objective-C code encrypting your secrects automatically. However, nowadays they refer to a bit fresh tool [Arkana](https://github.com/rogerluan/arkana) that I will focus on.

Arkana is a CLI tool that based on your configuration file and provided values generates either cocoapods or Swift Package Manager (SPM) package. This package contains swift implementation with encrypted secrets and decrypts them for you at runtime.

I personally prefer to install any tools related to a project by using [Bundler](https://bundler.io/). For that, you need to create a **Gemfile** that contains Arkana dependency requirement:

```
source "https://rubygems.org"

gem "arkana", "~> 1.4.0"
```

Please make sure to run `bundle install` before executing any of the following commands.

For Arkana, you first need to define your configuration file. You can check official configuration [template.yml](https://github.com/rogerluan/arkana/blob/main/template.yml) to see what options there are. For the demonstration project, I'll go with the bare minimum:

```
import_name: 'ArkanaKeys'
namespace: 'Keys'
result_path: 'ArkanaSecrets'
package_manager: spm
global_secrets:
  - ApiKey
```

Here's a little explanation:
- import_name - Package name that we will import.
- namespace - Structure name to access secrets at runtime.
- result_path - Directory where package is generated.
- package_manager - Package manager definition.
- global_secrets - List of our secrets, available for all app versions.

Another requirement is to provide actual values for defined keys. You can do so either by exporting keys as environment variables or creating a dedicated **.env** file like this:

```
ApiKey = "abcdefgh-ijkl-mnop-qrst-uvwxyz12"
```

We can now proceed and generate a package containing secrets. Below is the full command to execute. Configuration and environment values files may not be required based on their file names.

```
bundle exec arkana -c .arkana.yml -e .env
```

This should create an ArkanaSecrets directory with SPM package which we need to manually add to the project. Go to *File* -> *Add Packages...* and click on Add Local button (1).

![Add Local package](/assets/images/app_secrets_arkana_1.png)
*Add Local SPM package.*

From the selection window, select *ArkanaSecrets/ArkanaKeys* directory. This will make the package visible for Xcode.

![Add ArkanaKeys package](/assets/images/app_secrets_arkana_2.png)
*Add ArkanaKeys as local SPM package.*

Last integration step is to navigate to the project settings (1), select correct Target (2), then go to General tab (3) and add **ArkanaKeys** package to the **Frameworks, Libraries, and Embedded Content** section (4).

![Import ArkanaKeys package to the project](/assets/images/app_secrets_arkana_3.png)
*Import ArkanaKeys package to the project.*

Don't forget to add **.env** file to your **.gitignore** to not commit these in git. Ideally, do not commit entire *ArkanaSecrets* folder as it can be easily generated before every project build.

You can now read a key from your source code by importing the package **ArkanaKeys**. This can differ based on your configuration, however this is what it looks like in the demo project:

```
import ArkanaKeys

class ApiService {
  let apiKey = ArkanaKeys.Keys.Global().apiKey
}
```

Feel free to check the Arkana package content so you better understand where all your values are and how it is implemented under the hood.

By using this framework, we make sure secrets are not stored on git as plain text. Secrets are also no longer that easy accessible in the application IPA file. Plus we got rid of the need to handle optionals.

## Summary
Pros:
- Secrets not stored on git
- Encryption
- Secrets can differ per Configuration

Cons:
- Extra effort on new project members onboarding

# Final overview
| Option | Omitted from git | Hard to read from IPA | value per Configuration | Easy to setup |
| --- | :---: | :---: | :---: | :---: |
| Source code | 🔴 | 🔴 | 🟠 | 🟢 |
| Info.plist | 🔴 | 🔴 | 🔴 | 🟢 |
| Build Settings | 🔴 | 🔴 | 🟢 | 🟢 |
| xcconfig | 🟢 | 🔴 | 🟢 | 🟠 |
| Third party (Arkana) | 🟢 | 🟢 | 🟢 | 🟠 |

# Summary
You have seen several options on how to store application secrets. For each, some advantages and disadvantages were provided or demonstrated on the real demo project. This should help you to better understand your options when it comes to securing application secrets.

Keep in mind that it's never absolutely secure to store secrets on the client side. Even if they are not stored in git nor are easily extractable from the IPA file, they always have to be accessible at runtime which can also be risky. Anyway, we should at least try to make this as complicated as possible.

All code is available in the [repository](https://github.com/Fiser33/Fiser33.github.io/tree/main/examples/technical/app_secrets).