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

// Process gold system
app.post('/api/gold', (req, res) => {
  try {
    // Get client data
    const { currentGold, battleResult, winStreak, loseStreak, remainingGold } = req.body;
    
    // Validate data
    if (currentGold === undefined || battleResult === undefined) {
      return res.status(400).json({ error: 'Missing required data' });
    }
    
    let newGold = currentGold || 0;
    let goldGained = 0;
    let streakBonus = 0;
    let remainingBonus = 0;
    
    // Base gold for battle result
    if (battleResult === 'victory') {
      goldGained += 1; // Victory gives 1 gold
    }
    
    // Calculate streak bonus
    const winStreakCount = winStreak || 0;
    const loseStreakCount = loseStreak || 0;
    
    if (winStreakCount > 0) {
      if (winStreakCount >= 2 && winStreakCount <= 3) {
        streakBonus = 1;
      } else if (winStreakCount >= 4 && winStreakCount <= 5) {
        streakBonus = 2;
      } else if (winStreakCount >= 6) {
        streakBonus = 3;
      }
    } else if (loseStreakCount > 0) {
      if (loseStreakCount >= 2 && loseStreakCount <= 3) {
        streakBonus = 1;
      } else if (loseStreakCount >= 4 && loseStreakCount <= 5) {
        streakBonus = 2;
      } else if (loseStreakCount >= 6) {
        streakBonus = 3;
      }
    }
    
    // Calculate remaining gold bonus (capped at 5)
    if (remainingGold !== undefined) {
      remainingBonus = Math.min(Math.floor(remainingGold / 10), 5);
    }
    
    // Calculate total gold gain
    const totalBonus = streakBonus + remainingBonus;
    goldGained += totalBonus;
    newGold += goldGained;
    
    // Return result
    res.json({
      success: true,
      data: {
        newGold,
        goldGained,
        streakBonus,
        remainingBonus,
        totalBonus
      },
      message: `Gold processed successfully. Gained ${goldGained} gold.`
    });
  } catch (error) {
    console.error('Error processing gold:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Process turn start (for both experience and gold)
app.post('/api/turn/start', (req, res) => {
  try {
    // Get client data
    const { currentLevel, currentExperience, currentGold } = req.body;
    
    // Validate data
    if (currentLevel === undefined || currentExperience === undefined || currentGold === undefined) {
      return res.status(400).json({ error: 'Missing required data' });
    }
    
    // Validate level range
    if (currentLevel < 1 || currentLevel > 10) {
      return res.status(400).json({ error: 'Invalid level' });
    }
    
    let newLevel = currentLevel;
    let newExperience = currentExperience;
    let newGold = currentGold;
    let experienceGained = 0;
    let goldGained = 5; // Start of turn gives 5 gold
    
    // Process experience gain (start of turn)
    if (newLevel < 10) {
      experienceGained = 2;
      newExperience += experienceGained;
      
      // Calculate required experience for next level
      const requiredExperience = 2 * Math.pow(2, newLevel - 1);
      
      // Check for level up
      let levelUps = 0;
      while (newExperience >= requiredExperience && newLevel < 10) {
        newExperience -= requiredExperience;
        newLevel++;
        levelUps++;
      }
    }
    
    // Process gold gain (start of turn)
    newGold += goldGained;
    
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
        goldGained,
        requiredExperience: nextLevelRequiredExperience,
        maxLevelReached: newLevel >= 10
      },
      message: 'Turn started successfully'
    });
  } catch (error) {
    console.error('Error processing turn start:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Card pool management
// Initialize card pool
const cardPool = {
  1: { total: 36, remaining: 36 },
  2: { total: 36, remaining: 36 },
  3: { total: 36, remaining: 36 },
  4: { total: 18, remaining: 18 },
  5: { total: 9, remaining: 9 }
};

// Track non-shop purchased cards
const nonShopCards = {};

// Player state for shop and card slots
const playerState = {
  benchCards: [],
  battlefieldCards: [],
  currentLevel: 1,
  maxBenchSlots: 10
};

// Generate shop cards (5 cards)
function generateShopCards() {
  const shopCards = [];
  const cardTypes = [1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 5];
  
  for (let i = 0; i < 5; i++) {
    const randomIndex = Math.floor(Math.random() * cardTypes.length);
    const cost = cardTypes[randomIndex];
    
    if (cardPool[cost].remaining > 0) {
      shopCards.push({
        id: `${cost}_${Date.now()}_${i}`,
        cost: cost,
        star: 1,
        name: `Card_${cost}_${i}`
      });
    }
  }
  
  return shopCards;
}

// Current shop cards
let shopCards = generateShopCards();

// Process card actions
app.post('/api/cards', (req, res) => {
  try {
    const { action, cardCost, cardStar, isShopPurchase, cardId, cardName, shopRefreshCost } = req.body;
    
    // Validate data
    if (!action) {
      return res.status(400).json({ error: 'Missing required data' });
    }
    
    let result = {};
    
    switch (action) {
      case 'get_shop':
        // Get current shop cards
        result = {
          message: 'Shop cards retrieved',
          shopCards: shopCards,
          benchCards: playerState.benchCards,
          battlefieldCards: playerState.battlefieldCards,
          maxBenchSlots: playerState.maxBenchSlots,
          maxBattlefieldSlots: playerState.currentLevel
        };
        break;
        
      case 'refresh_shop':
        // Refresh shop (can get duplicate cards)
        const refreshCost = shopRefreshCost || 2;
        shopCards = generateShopCards();
        result = {
          message: `Shop refreshed for ${refreshCost} gold`,
          shopCards: shopCards
        };
        break;
        
      case 'buy':
        // Buy card from shop
        if (playerState.benchCards.length >= playerState.maxBenchSlots) {
          return res.status(400).json({ error: 'Bench is full' });
        }
        
        // Find the card in shop
        const cardIndex = shopCards.findIndex(c => c.id === cardId);
        if (cardIndex === -1) {
          return res.status(400).json({ error: 'Card not found in shop' });
        }
        
        const card = shopCards[cardIndex];
        
        // Check card pool
        if (cardPool[card.cost].remaining <= 0) {
          return res.status(400).json({ error: 'Card out of stock' });
        }
        
        // Remove from shop
        shopCards.splice(cardIndex, 1);
        
        // Add to bench
        playerState.benchCards.push({
          ...card,
          isShopPurchase: true,
          uniqueId: `${card.cost}_${Date.now()}`
        });
        
        // Decrease card pool
        cardPool[card.cost].remaining--;
        
        result = {
          message: 'Card purchased successfully',
          cardPool: cardPool,
          benchCards: playerState.benchCards,
          shopCards: shopCards
        };
        break;
        
      case 'sell':
        // Sell card from bench or battlefield
        const sellCost = cardCost || 1;
        const sellStar = cardStar || 1;
        
        if (isShopPurchase) {
          let cardsToReturn = 1;
          if (sellStar === 2) {
            cardsToReturn = 3;
          } else if (sellStar === 3) {
            cardsToReturn = 9;
          }
          
          // Return cards to pool
          cardPool[sellCost].remaining = Math.min(
            cardPool[sellCost].total,
            cardPool[sellCost].remaining + cardsToReturn
          );
          result = {
            message: `Card sold successfully, returned ${cardsToReturn} cards to pool`,
            cardPool: cardPool[sellCost],
            cardsReturned: cardsToReturn
          };
        } else {
          result = {
            message: 'Card sold successfully, not returned to pool',
            cardPool: cardPool[sellCost]
          };
        }
        break;
        
      case 'combine':
        // Combine cards to higher star (must be same card name/type)
        if (!cardStar || cardStar < 1 || cardStar > 2) {
          return res.status(400).json({ error: 'Invalid card star for combination' });
        }
        
        // Find cards with same name in bench
        if (!cardName) {
          return res.status(400).json({ error: 'Card name required for combination' });
        }
        
        // Count same cards in bench
        const sameCards = playerState.benchCards.filter(c => c.name === cardName && c.star === cardStar);
        
        if (sameCards.length < 3) {
          return res.status(400).json({ error: 'Need 3 identical cards to combine' });
        }
        
        // Track non-shop purchased cards for later selling
        if (!nonShopCards[cardCost]) {
          nonShopCards[cardCost] = 0;
        }
        nonShopCards[cardCost] += 3;
        
        result = {
          message: 'Cards combined successfully',
          nonShopCards: nonShopCards[cardCost],
          newStar: cardStar + 1
        };
        break;
        
      case 'place_card':
        // Place card from bench to battlefield
        const battlefieldSize = playerState.battlefieldCards.length;
        const maxBattlefieldSize = playerState.currentLevel;
        
        if (battlefieldSize >= maxBattlefieldSize) {
          return res.status(400).json({ error: `Battlefield is full (max ${maxBattlefieldSize} cards)` });
        }
        
        // Find card in bench
        const benchCardIndex = playerState.benchCards.findIndex(c => c.id === cardId);
        if (benchCardIndex === -1) {
          return res.status(400).json({ error: 'Card not found in bench' });
        }
        
        // Move card from bench to battlefield
        const benchCard = playerState.benchCards.splice(benchCardIndex, 1)[0];
        playerState.battlefieldCards.push(benchCard);
        
        result = {
          message: 'Card placed to battlefield',
          benchCards: playerState.benchCards,
          battlefieldCards: playerState.battlefieldCards
        };
        break;
        
      case 'return_card':
        // Return card from battlefield to bench
        if (playerState.benchCards.length >= playerState.maxBenchSlots) {
          return res.status(400).json({ error: 'Bench is full' });
        }
        
        // Find card in battlefield
        const battlefieldCardIndex = playerState.battlefieldCards.findIndex(c => c.id === cardId);
        if (battlefieldCardIndex === -1) {
          return res.status(400).json({ error: 'Card not found in battlefield' });
        }
        
        // Move card from battlefield to bench
        const battlefieldCard = playerState.battlefieldCards.splice(battlefieldCardIndex, 1)[0];
        playerState.benchCards.push(battlefieldCard);
        
        result = {
          message: 'Card returned to bench',
          benchCards: playerState.benchCards,
          battlefieldCards: playerState.battlefieldCards
        };
        break;
        
      case 'update_level':
        // Update player level (affects battlefield size)
        playerState.currentLevel = currentLevel || 1;
        result = {
          message: 'Player level updated',
          maxBattlefieldSlots: playerState.currentLevel
        };
        break;
        
      case 'get_pool':
        // Get current card pool status
        result = {
          message: 'Card pool status retrieved',
          cardPool: cardPool
        };
        break;
        
      default:
        return res.status(400).json({ error: 'Invalid action' });
    }
    
    // Return result
    res.json({
      success: true,
      data: result
    });
  } catch (error) {
    console.error('Error processing card action:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});