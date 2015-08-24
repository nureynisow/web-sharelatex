PLMStrategy 				= require('passport-plm-oauth2').Strategy
GoogleStrategy 				= require('passport-google-oauth').OAuth2Strategy
AuthenticationController 	= require './AuthenticationController'

User	= require('../../models/User').User
Settings = require 'settings-sharelatex'
configAuth = Settings

module.exports = (passport) ->
	passport.serializeUser (user,done)->
		done null,user.id
	passport.deserializeUser (id,done)->
		User.findById id,(err,user)->
			done err,user

	passport.use 'plm', new PLMStrategy {
		authorizationURL	: configAuth.plmAuth.authorizationURL
		tokenURL			: configAuth.plmAuth.tokenURL
		clientID			: configAuth.plmAuth.clientID
		clientSecret		: configAuth.plmAuth.clientSecret
		callbackURL			: configAuth.plmAuth.callbackURL
	},(token,secretToken,profile,done)->
			process.nextTick ()->
				profile = JSON.parse(profile);
				User.findOne {'email':profile.email},(err,user)->
					if err
						done err
					if user 
						done null,user
					else
						newUser = new User
						newUser.email = profile.email
						newUser.first_name = profile.convergence_data.CN
						newUser.last_name = profile.convergence_data.SN
						newUser.confirmed = true
						newUser.passport = true
						newUser.save (err)->
							if err
								throw err
							done null,newUser

	passport.use new GoogleStrategy {
    	clientID		: configAuth.googleAuth.clientID,
    	clientSecret	: configAuth.googleAuth.clientSecret
    	callbackURL		: configAuth.googleAuth.callbackURL
	},(token,secretToken,profile,done)->
			console.log "profile",profile
			process.nextTick ()->
				User.findOne {'email' : profile.emails[0].value}, (err,user)->
					if err
						done err
					if user
						done null,user
					else
						newUser = new User
						newUser.first_name = profile.displayName
						newUser.email = profile.emails[0].value
						newUser.confirmed = true
						newUser.passport = true

						newUser.save (err)->
							if err
								throw err
							done(null, newUser)


		
	
