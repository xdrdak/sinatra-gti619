Final project for GTI619
=======================

### Please note that this is still a W.I.P

## Installing the project

Assuming you've cloned the repo.

1. Make sure Ruby is installed on your machine. If you're on windows the fastest way is by using [ruby installer](http://rubyinstaller.org/)
2. Install bundler by running `gem install bundler`
3. In the project folder, run `bundle install` to get all the necessary modules/plugins to get the app running
4. Start the server using `shotgun`

If you launch the application for the first time, a new sqlite database will be created in the /db folder. New users will also be created. You can checkout /models/init.rb for the users that will be created.

## Important things to remember

You'll need to create your own SSL certificate for the app to work. Just follow [this heroku guide](https://devcenter.heroku.com/articles/ssl-certificate-self) to generate whatever you need, then shove everthing into the root folder.

You have to make a config.yml. Once you pull/fork the project, make sure to create a new folder called "config" at the root of the application. Afterwards, create a file called `config.yml`. It's content should be something like this :
``` 
server_email_user: USERNAME_OF_GMAIL_ACCOUNT
server_email_pw: PASSWORD_OF_GMAIL_ACCOUNT
```


### Components
The sinatra-warden-template was used as the basis for the authentication module. From there, I just changed a couple of things or made it more modular. Big thanks to the author of the template.

sinatra-warden-template      [Link for Repo](https://github.com/erikwco/sinatra-warden-template)

