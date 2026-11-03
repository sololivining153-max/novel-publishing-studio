# Integration status

The three previously separate feature modules have been copied into the Story Architect MVP backend and their routers are registered in `backend/app/main.py`.

- Story Intelligence models are registered before SQLAlchemy `create_all()`.
- Story Intelligence and Novel Writer routers receive the shared database dependency, Project model and model registry.
- Literary Editor router is registered; review execution remains prompt-ready until an AI adapter is wired.
- Flutter screens from all three modules are included as source files. They are not yet fully connected into the home navigation and need UI integration and device testing.

Security warning: project endpoints currently have no user authentication/ownership enforcement. Keep this service private and local until that is implemented.
