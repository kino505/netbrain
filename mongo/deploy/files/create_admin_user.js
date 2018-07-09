sleep(5000);
db.createUser({ user: 'MONGO_ADMIN_USERNAME', pwd: 'MONGO_ADMIN_PASSWORD', roles: [ { role: "root", db: "admin" } ] });
