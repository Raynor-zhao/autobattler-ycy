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

// Process experience system
app.post('/api/experience', (req, res) => {
  try {
    // Get client data
    const { currentLevel, currentExperience, action, gold } = req.body;
    
    // Validate data
    if (currentLevel === undefined || currentExperience === undefined || action === undefined) {
      return res.status(400).json({ error: 'Missing required data' });
    }
    
    // Validate level range
    if (currentLevel < 1 || currentLevel > 10) {
      return res.status(400).json({ error: 'Invalid level' });
    }
    
    // Check if max level reached
    if (currentLevel >= 10) {
      return res.status(400).json({ error: 'Already at max level' });
    }
    
    let newLevel = currentLevel;
    let newExperience = currentExperience;
    let newGold = gold || 0;
    let experienceGained = 0;
    let goldSpent = 0;
    
    // Calculate required experience for next level
    const requiredExperience = 2 * Math.pow(2, newLevel - 1);
    
    switch (action) {
      case 'start_turn':
        // Start of turn: gain 2 experience
        experienceGained = 2;
        newExperience += experienceGained;
        break;
        
      case 'buy_experience':
        // Buy experience: cost 4 gold, gain 4 experience
        if (newGold < 4) {
          return res.status(400).json({ error: 'Not enough gold' });
        }
        goldSpent = 4;
        experienceGained = 4;
        newGold -= goldSpent;
        newExperience += experienceGained;
        break;
        
      case 'battle_reward':
        // Battle reward: gain 2 experience (cost 2 gold)
        if (newGold < 2) {
          return res.status(400).json({ error: 'Not enough gold' });
        }
        goldSpent = 2;
        experienceGained = 2;
        newGold -= goldSpent;
        newExperience += experienceGained;
        break;
        
      default:
        return res.status(400).json({ error: 'Invalid action' });
    }
    
    // Check for level up
    let levelUps = 0;
    while (newExperience >= requiredExperience && newLevel < 10) {
      newExperience -= requiredExperience;
      newLevel++;
      levelUps++;
    }
    
    // Calculate required experience for next level after potential level up
    const nextLevelRequiredExperience = newLevel < 10 ? 2 * Math.pow(2, newLevel - 1) : 0;
    
    // Return result
    res.json({
      success: true,
      data: {
        newLevel,
        newExperience,
        newGold,
        experienceGained,
        goldSpent,
        levelUps,
        requiredExperience: nextLevelRequiredExperience,
        maxLevelReached: newLevel >= 10
      },
      message: levelUps > 0 ? `Leveled up ${levelUps} time(s)!` : 'Experience processed successfully'
    });
  } catch (error) {
    console.error('Error processing experience:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});