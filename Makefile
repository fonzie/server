reset:
	@heroku pg:reset HEROKU_POSTGRESQL_NAVY && heroku restart