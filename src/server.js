const app = require('./app');

const init = (port) => {
  try {
    app.listen(port, () => {
      console.log('Express App Listening on Port 3001');
    });
  } catch (error) {
    console.error(`An error occurred: ${JSON.stringify(error)}`);
    process.exit(1);
  }
};

init(3001);