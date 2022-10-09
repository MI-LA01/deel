const express = require('express');
const bodyParser = require('body-parser');
const {sequelize} = require('./model')
const {getProfile} = require('./middleware/getProfile')
const app = express();
app.use(bodyParser.json());
app.set('sequelize', sequelize)
app.set('models', sequelize.models)


//This API is broken 😵! it should return the contract only if it belongs to the profile calling. better fix that!
app.get('/contract/:id', getProfile , async (req, res) => {
    const id = parseInt(req.params.id) //missing test. 
    const contract = await req.profile.getContractById(id)
    if(!contract) return res.status(404).end()
    res.json(contract)
})

//Returns a list of contracts belonging to a user (client or contractor), the list should only contain non terminated contracts.
app.get('/contracts', getProfile, async (req, res) => {
    const contracts = await req.profile.getContracts();
    if(!contracts || contracts.length == 0) return res.status(404).end()
    res.json(contracts)
})

//Get all unpaid jobs for a user (***either*** a client or contractor), for ***active contracts only***.
app.get('/jobs/unpaid', getProfile, async (req, res) => {
   const jobs = await req.profile.getAllActiveAndUnPaidJobs()
   if(!jobs || jobs.length == 0)  return res.status(404).end()
   res.json(jobs)
})

//Pay for a job, a client can only pay if his balance >= the amount to pay. The amount should be moved from the client's balance to the contractor balance.
app.post('/jobs/:job_id/pay', getProfile, async (req, res) => {
    const job_id = req.params.job_id;
    const txRet = await req.profile.payContractorByJobId(job_id);
    res.json(txRet)
})

/**
 * Deposits money into the the the balance of a client, a client can't deposit more than 25% his total of jobs to pay. (at the deposit moment)
 * 
 * A client to deposit money to another one..
 */
app.post('/balances/deposit/:userId', getProfile, async (req, res) => {
    const userId = parseInt(req.params.userId)
    const amount = parseInt(req.query.amount)
    const status = await req.profile.depositToClient(amount, userId);
    res.json(status)
})

//Returns the profession that earned the most money (sum of jobs paid) for any contactor that worked in the query time range.
app.get('/admin/best-profession', async (req, res) => {    
    const {Job} = req.app.get('models');
    const startDate = new Date(req.query.start)
    const endDate =  new Date(req.query.end)

    if(!(startDate instanceof Date && !isNaN(startDate) && endDate instanceof Date && !isNaN(endDate)))
        return res.status(404).end()

    const topJobs = await Job.getTopRevenueJobsByDateRange(startDate, endDate);

    res.json(topJobs)
})

//returns the clients the paid the most for jobs in the query time period. limit query parameter should be applied, default limit is 2.
app.get('/admin/best-clients', async (req, res) =>{
    const {Job} = req.app.get('models');
    const startDate = new Date(req.query.start)
    const endDate =  new Date(req.query.end)
    const limit = parseInt(req.query.limit)

    if(!(startDate instanceof Date && !isNaN(startDate) && endDate instanceof Date && !isNaN(endDate)))
        return res.status(404).end()

    const topClients = await Job.getTopPaidClientsByDateRange(startDate, endDate, limit);
    //console.log("xx");
    res.json(topClients)
})

module.exports = app;
