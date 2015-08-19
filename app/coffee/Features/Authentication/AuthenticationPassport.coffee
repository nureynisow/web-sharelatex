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
				# console.log "profile",profile
				User.findOne {'plm.id':profile.id},(err,user)->
					if err
						done err
					if user 
						# console.log 'user exist',user
						done null,user
					else
						# console.log 'creating user '+profile.class
						newUser = new User
						newUser.plm.id = profile.id
						newUser.plm.uid = profile.uid
						newUser.plm.email  = profile.email
						newUser.email = profile.email
						newUser.plm.displayName =  profile.convergence_data.displayName
						newUser.first_name = profile.convergence_data.CN
						newUser.last_name = profile.convergence_data.SN
						newUser.confirmed = true
						newUser.save (err)->
							if err
								throw err
							done null,newUser



	passport.use new GoogleStrategy {
    	clientID		: configAuth.googleAuth.clientID,
    	clientSecret	: configAuth.googleAuth.clientSecret
    	callbackURL		: configAuth.googleAuth.callbackURL
	},(token,secretToken,profile,done)->
			# console.log req, res, profile
			process.nextTick ()->
				User.findOne {'google.id' : profile.id}, (err,user)->
					if err
						done err
					if user
						done null,user
					else
						newUser = new User
						newUser.google.id = profile.id
						newUser.google.name = newUser.first_name = profile.displayName
						newUser.google.email = newUser.email = profile.emails[0].value
						newUser.google.token = token
						newUser.confirmed = true

						newUser.save (err)->
							if err
								throw err
							done(null, newUser)


		
	
