use rvx-bigdata-db;


db.createUser({
   user: "rvxbigdataus",
   pwd: "455ttte",
   roles: [ { role: "readWrite", db: "rvx-bigdata-db" } ]
});