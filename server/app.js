const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(helmet());
app.use(morgan('combined'));
app.use(express.json());

// Routes
app.get('/', (req, res) => {
  res.json({ message: 'Autobattler Server is running!' });
});

// Process client data
app.post('/api/process', (req, res) => {
  try {
    // Get client data
    const clientData = req.body;
    
    // Validate data
    if (!clientData) {
      return res.status(400).json({ error: 'No data provided' });
    }
    
    if (!clientData.units || !Array.isArray(clientData.units)) {
      return res.status(400).json({ error: 'Invalid units data' });
    }
    
    // Calculate battle result
    const result = calculateBattleResult(clientData);
    
    // Return result
    res.json({
      success: true,
      data: result,
      message: 'Battle processed successfully'
    });
  } catch (error) {
    console.error('Error processing data:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Calculate battle result function
function calculateBattleResult(data) {
  // Extract units
  const units = data.units;
  
  // Calculate total power
  const totalPower = units.reduce((sum, unit) => {
    return sum + (unit.power || 0);
  }, 0);
  
  // Calculate average power
  const averagePower = units.length > 0 ? totalPower / units.length : 0;
  
  // Determine battle result based on total power
  let battleResult = 'defeat';
  if (totalPower > 1000) {
    battleResult = 'victory';
  } else if (totalPower > 500) {
    battleResult = 'draw';
  }
  
  // Generate result
  return {
    totalPower,
    averagePower,
    unitCount: units.length,
    battleResult,
    timestamp: new Date().toISOString(),
    processedUnits: units.map(unit => ({
      id: unit.id,
      name: unit.name,
      power: unit.power,
      status: unit.power > 100 ? 'active' : 'inactive'
    }))
  };
}

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});