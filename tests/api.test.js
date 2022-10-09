
const app = require("../src/app");
const request = require('supertest')

describe('Jobs Endpoints', () => {
  it('POST /jobs/:id/pay should pay the pending job 4 from client Mr Robot to Alan Turing', async () => {
    const res = await request(app).post('/jobs/4/pay').set({ 'profile_id': 2 })
    expect(res.status).toEqual(200);
    expect(res.type).toEqual(expect.stringContaining('json'));
    expect(res.body).toHaveProperty('paid', true)
  });

  it('POST /jobs/:id/pay job 4 should not pass this time', async () => {
    const res = await request(app).post('/jobs/4/pay').set({ 'profile_id': 2 })
    expect(res.status).toEqual(200);
    expect(res.type).toEqual(expect.stringContaining('json'));
    expect(res.body).toHaveProperty('paid', false)
  });

  it('GET /jobs/unpaid should returns 404 and no unpaid jobs for the user id 3', async () => {
      const res = await request(app).get('/jobs/unpaid').set({ 'profile_id': 3 })
      expect(res.status).toEqual(404);
  });

  it('GET /jobs/unpaid should show 3 unpaid jobs for the user id 1', async () => {
    const res = await request(app).get('/jobs/unpaid').set({ 'profile_id': 1 })
    expect(res.status).toEqual(200);
    expect(res.type).toEqual(expect.stringContaining('json'));
    expect(res.body).toHaveLength(3);
    res.body.forEach(element => {
      expect(element).toHaveProperty('id')
      expect(element).toHaveProperty('description', 'work')
      expect(element).toHaveProperty('price')
      expect(element).toHaveProperty('paid', false)
      expect(element).toHaveProperty('paymentDate', null)
      expect(element).toHaveProperty('ContractId', 2)
    });
  });


})

describe('Contracts Endpoints', () => {
  it('GET /contracts should show 1 contract for the user id 1', async () => {
    const res = await request(app).get('/contracts').set({ 'profile_id': 1 })
    expect(res.status).toEqual(200);
    expect(res.type).toEqual(expect.stringContaining('json'));
    expect(res.body).toHaveLength(1);
    res.body.forEach(element => {
      expect(element).toHaveProperty('id')
      expect(element).toHaveProperty('terms')
      expect(element).toHaveProperty('status', 'in_progress')
      expect(element).toHaveProperty('ContractorId', 6)
      expect(element).toHaveProperty('ClientId', 1)
    });
  });

  it('GET /contracts should show 3 contract for the user id 6', async () => {
    const res = await request(app).get('/contracts').set({ 'profile_id': 6 })
    expect(res.status).toEqual(200);
    expect(res.type).toEqual(expect.stringContaining('json'));
    expect(res.body).toHaveLength(3);
    res.body.forEach(element => {
      expect(element).toHaveProperty('id')
      expect(element).toHaveProperty('terms')
      expect(element).toHaveProperty('status')
      expect(element).toHaveProperty('ContractorId', 6)
    });
  });

  it('GET /contract/:id should show 1 terminated contract for the contract id 1 and profile_id 1', async () => {
    const res = await request(app).get('/contract/1').set({ 'profile_id': 1 })
    expect(res.status).toEqual(200);
    expect(res.type).toEqual(expect.stringContaining('json'));
    expect(res.body).toHaveProperty('id')
    expect(res.body).toHaveProperty('terms')
    expect(res.body).toHaveProperty('status', 'terminated')
    expect(res.body).toHaveProperty('ContractorId', 5)
    expect(res.body).toHaveProperty('ClientId', 1)
  });

  it('GET /contract/:id should show 1 in_progress contract for the contract id 2 and profile_id 1', async () => {
    const res = await request(app).get('/contract/2').set({ 'profile_id': 1 })
    expect(res.status).toEqual(200);
    expect(res.type).toEqual(expect.stringContaining('json'));
    expect(res.body).toHaveProperty('id')
    expect(res.body).toHaveProperty('terms')
    expect(res.body).toHaveProperty('status', 'in_progress')
    expect(res.body).toHaveProperty('ContractorId', 6)
    expect(res.body).toHaveProperty('ClientId', 1)
  });

  it('GET /contract/:id should return 404 for the contract id 5 and profile_id 1', async () => {
    const res = await request(app).get('/contract/5').set({ 'profile_id': 1 })
    expect(res.status).toEqual(404);
  });
});