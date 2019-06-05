pragma solidity >=0.4.22 <0.6.0;
//
//___________________________________________________________________
//  _      _                                        ______           
//  |  |  /          /                                /              
//--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
//  |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
//__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_
//
//
//
//████████╗██████╗  ██████╗ ███╗   ██╗    ████████╗ ██████╗ ██████╗ ██╗ █████╗ 
//╚══██╔══╝██╔══██╗██╔═══██╗████╗  ██║    ╚══██╔══╝██╔═══██╗██╔══██╗██║██╔══██╗
//   ██║   ██████╔╝██║   ██║██╔██╗ ██║       ██║   ██║   ██║██████╔╝██║███████║
//   ██║   ██╔══██╗██║   ██║██║╚██╗██║       ██║   ██║   ██║██╔═══╝ ██║██╔══██║
//   ██║   ██║  ██║╚██████╔╝██║ ╚████║       ██║   ╚██████╔╝██║     ██║██║  ██║
//   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝       ╚═╝    ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝
//                                                                             
//  
// ----------------------------------------------------------------------------
// 'LuckyOne' Token contract with following features:
//      => Random dice rolls
//      => SafeMath implementation 
//      => 5 * Multiplyers
//      => Burnable and minting (only by game players as they play the games)
//      => Adjustable winning conditions
//      => Adjustable total prize
//      => Audited by : TBC
// Name        : Topia
// Symbol      : TOP
// Total supply: 0 (Minted only by game players only)
// Decimals    : 8
//
// Copyright (c) 2019 onwards TRONtopia Inc. ( https://trontopia.co )
// ----------------------------------------------------------------------------
//*/ 

//**********************************************************************************************************************************************//
//------------------ SAFE MATH------------------------------------------------------------------------------------------------------------------//
//**********************************************************************************************************************************************//
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

//**********************************************************************************************************************************************//
//------------------ SECURITY ------------------------------------------------------------------------------------------------------------------//
//**********************************************************************************************************************************************//
    //Add contract ignore
    //Add fund recieve callback
contract owned {
    address payable public owner;
    constructor() payable public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        owner = newOwner;
    }
}

//*****************************************************************************************************************************************************//
//---------------------  TRONTOPIA CONTRACT INTERFACE  ------------------------------------------------------------------------------------------------//
//*****************************************************************************************************************************************************//

interface TRONtopiaInterface {
    function transfer(address recipient, uint amount) external returns(bool);
    function mintToken(address _user, uint256 _tronAmount)  external returns(bool);
    function referrers(address user) external returns(address);
    function updateReferrer(address _user, address _referrer) external returns(bool);
    function payReferrerBonusOnly(address _user, uint256 _refBonus, uint256 _trxAmount ) external returns(bool);
    function payReferrerBonusAndAddReferrer(address _user, address _referrer, uint256 _trxAmount, uint256 _refBonus) external returns(bool);
} 

//*****************************************************************************************************************************************************//
//-----------------------GLOBAL VALUES-----------------------------------------------------------------------------------------------------------------//
//*****************************************************************************************************************************************************//

contract Luckyone is owned{
    using SafeMath for uint256;
    //Reduce uints and add safemath for them
    address private mainContractAddress = address(this);
    address public topiaTokenContractAddress;
    uint8 multiplierOneVal;
    uint8 multiplierTwoVal;
    uint8 multiplierThreeVal;
    uint8 multiplierFourVal;
    uint8 multiplierFiveVal;
    uint256 internal tronDecimals=6;
    uint256 public betPrice = 10 * (10**tronDecimals);  
    uint256 nonce;
 
 //*****************************************************************************************************************************************************//
//-----------------------EVENTS-------------------------------------------------------------------------------------------------------------------------//
//*****************************************************************************************************************************************************//
    // Notify game result
    event GameResult(address indexed user, uint256 timestamp, uint256 NoOfLuckyNumbers,uint256 winnings); 

    // Notify Game 2 result
    event Game2Result(address indexed user, uint256 timestamp, uint256 val1BetWinnigns, uint256 val2BetWinnigns, 
                    uint256 val3BetWinnigns, uint256 val4BetWinnigns, uint256 val5BetWinnigns, uint256 val6BetWinnigns); 
    
    //Administration Notifications
    event ContracOwnerUpdated(bool);
    event ManualWithdraw(bool);
    event ManualSubmittion(bool);

//*****************************************************************************************************************************************************//
//-----------------------MULTIPLIERS-------------------------------------------------------------------------------------------------------------------//
//*****************************************************************************************************************************************************//
    //choose multiplier calulation * value
    function multiplierOne(uint8 _newMultiplier) public onlyOwner returns (uint8) {
        // awaiting information
        multiplierOneVal = _newMultiplier;
        return multiplierOneVal;
    }
    
    //choose multiplier calulation * value
     function multiplierTwo(uint8 _newMultiplier) public onlyOwner returns (uint8) {
        multiplierTwoVal = _newMultiplier;
        return multiplierTwoVal;
    }
    
    //choose multiplier calulation * value
     function multiplierThree(uint8 _newMultiplier) public onlyOwner returns (uint8) {
        multiplierThreeVal = _newMultiplier;
        return multiplierThreeVal;
    }
    
    //choose multiplier calulation * value
     function multiplierFour(uint8 _newMultiplier) public onlyOwner returns (uint8) {
        multiplierFourVal = _newMultiplier;
        return multiplierFourVal;
    }
    
    //choose multiplier calulation * value
     function multiplierFive(uint8 _newMultiplier) public onlyOwner returns (uint8) {
        multiplierFiveVal = _newMultiplier;
        return multiplierFiveVal;
    }

//*****************************************************************************************************************************************************//
//-----------------------FUNDS MOVEMENT----------------------------------------------------------------------------------------------------------------//
//*****************************************************************************************************************************************************//
    // Recieve a bet
    function recieveBet(uint256 value) internal returns (uint256,address) {            
            TRONtopiaInterface(topiaTokenContractAddress).mintToken(msg.sender, msg.value);
            uint256 bet = value;
            address payable betAddressSource = msg.sender;
            return (bet, betAddressSource);
    }
    
    //Payout winnings
    function payOut() internal {
        //address log = msg.sender();  //temp log
        require(msg.sender != owner, "You cannot call this function.  Your Wallet ID has been logged.");
        require(msg.sender != msg.sender, "You cannot call this function.  Your Wallet ID has been logged.");
        //Add not callable by another contract

        uint256 winnings = 0; //calulate winnings from winnigns function
        msg.sender.transfer(winnings);
    }
    
    //calculate actual winnings
    function calculateActualWinnings(uint8 multiCount,uint256 bet) internal returns (uint256) {
        //need to change multiplier types to uint256 to extend multiplier number
        if (multiCount == 0) {
            uint256 multiOneWinnings = 0;
            return multiOneWinnings;
        }

        if (multiCount == 1) {
            uint256 multiOneWinnings = multiplierOne(2) * bet;
            return multiOneWinnings;
        }

        if (multiCount == 2) {
            uint256 multiTwoWinnings = multiplierTwo(3) * bet;
            return multiTwoWinnings;
        }

        if (multiCount == 3) {
            uint256 multiThreeWinnings = multiplierThree(6) * bet;
            return multiThreeWinnings;
        }

        if (multiCount == 4) {
            uint256 multiFourWinnings = multiplierFour(200) * bet;
            return multiFourWinnings;
        }

        if (multiCount == 5) {
            uint256 multiFiveWinnings = multiplierFive(255) * bet;
            return multiFiveWinnings;
        }

    }
 
//*****************************************************************************************************************************************************//
//-----------------------PROBABILITY CHANGER-----------------------------------------------------------------------------------------------------------//
//*****************************************************************************************************************************************************//

//need further clarify on these
    function changeRandomness() internal view {
        // awaiting information
    }

    //makes sure a number does not land above 0 or 1 else returns 0.  This only controls the first number in a number of length
    // 100,000, venting the possibility of the number going above 100,000.
    function controlProbability(uint8 input) internal pure returns (uint8) {
        if (input == 11) {
            return 1;
        }

        if (input == 10) {
            return 0;
        }

        if (input > 11) {
            return 0;
        }
    }

//*****************************************************************************************************************************************************//
//-----------------------GAME--------------------------------------------------------------------------------------------------------------------------//
//*****************************************************************************************************************************************************//
    //This game rolls a random number between 0 - 100,000.  Any occurances of the number '1' within the 
    //Roll results in the user winning.  It is further randomized by recieving a chosen number by the user.

    //Randomize Nonce
    function randomizeNonce(uint256) internal view returns (uint256) {
        uint randomNonce = uint(keccak256(abi.encodePacked(now,now+now+10, msg.sender, nonce))) % 999 * 1001;
        return randomNonce;
    }

    //Randomize Seed
    function randomizeSeed(uint256 seed) internal view returns (uint256) {
        uint randomSeed = uint(keccak256(abi.encodePacked(now,now+now+10, msg.sender, seed))) % 999 * 1001;
        return randomSeed;
    }

    //Randomize multiplyer
    function randomizeMulti() internal view returns(uint256) {
        uint256 num = uint(keccak256(abi.encodePacked(now,now+now+10, msg.sender))) % 999 * 1001;
        return num;
    }

    //Generate Random Number
    function random(uint256 seed) internal returns (uint) {
        uint256 randomNonce =  randomizeNonce(nonce);
        uint256 randomSeed =  randomizeSeed(seed);
        uint randomnumber = uint(keccak256(abi.encodePacked(now,now+now+10, msg.sender, randomNonce, nonce, randomSeed, seed))) % 100 * randomizeMulti();
        randomnumber = randomnumber;
        nonce++;
        return randomnumber;
    }
    //Gather random numbers into individual number lines
    function gatherNumbers(uint256 seed) internal returns (uint8,uint8,uint8,uint8,uint8,uint8){
        uint8 unit1 = uint8(random(seed)) / 3; //change to 3
        uint8 unit2 = uint8(random(seed))/ 3;
        uint8 unit3 = uint8(random(seed))/ 3;
        uint8 unit4 = uint8(random(seed))/ 3;
        uint8 unit5 = uint8(random(seed))/ 3;
        uint8 unit6 = uint8(random(seed))/ 3;
        
        return (controlProbability(unit1), //Ensure the first number can only be a range of 0-1, not 0-9
                unit2,
                unit3,
                unit4,
                unit5,
                unit6);
    }
    
    //Run the main game's background tasks for efficency.  Splits the main game functions to prevent value overflowing in main game.
    function backgroundTasks(uint256 seed) internal returns (uint8,uint8,uint8,uint8,uint8,uint8,uint8) {
        
        uint8 val1;
        uint8 val2;
        uint8 val3;
        uint8 val4;
        uint8 val5;
        uint8 val6;
        
        //Gets the random numbers
        (val1,val2,val3,val4,val5,val6) = gatherNumbers(seed);

        //Checks which numbers are winning numbers
        uint8 multiCount = multiplierCheck(val1,val2,val3,val4,val5,val6);

        //Returns each number, plus a count of number of winning numbers to main game
        //Multi Count: Total count of all winning numbers
        return (multiCount,val1,val2,val3,val4,val5,val6);
    }

    //Run the main game
    function runGame(uint256 seed, uint256 _bet) public payable returns (uint8) {
        //Pulls all the information from background Tasks function
        (uint8 multiCount,uint8 val1,uint8 val2, uint8 val3, uint8 val4, uint8 val5,uint8 val6) = backgroundTasks(seed);

        //Calculates actual winnings for user
        uint256 winnings = calculateActualWinnings(multiCount,_bet);

        // Notify game result
        emit GameResult(msg.sender, now, multiCount,winnings); 

        return multiCount;
    }
    
    //Check for winning number
    function checkResult(uint8 val) private pure returns (bool) {
        //The numbers are in double digits for efficency savings of gas.  This function checks the first value of the results to determine which value 
        //has the number '1' as its first value.  
        if (val == 10 || val == 11 || val == 12 || val == 13 || val == 14 || val == 15 || val == 16 || val == 17 || val == 18 || val == 19 || val == 1) {
            bool result = true;
            return result;
         }
    }
    
    //count how many occurances of 1 have occured for muliplier calculation
    function multiplierCheck(uint8 val1, uint8 val2 , uint8 val3, uint8 val4, uint8 val5, uint8 val6) private pure returns (uint8) {
        uint8 count = 0;
        //Checks each input value to see if it contains a '1' as its first digit, which is assigned the value true in the previous
        //Function.  If marked as true, it is counted as +1, for winnings calculations.
        if (checkResult(val1) == true) {
            count = count + 1;   
        }
        
        if (checkResult(val2) == true) {
            count = count + 1;   
        }
        
        if (checkResult(val3) == true) {
            count = count + 1;    
        }
        
        if (checkResult(val4) == true) {
            count = count + 1;    
        }
        
        if (checkResult(val5) == true) {
            count = count + 1;    
        }
        
        if (checkResult(val6) == true) {
            count = count + 1;    
        }
        
        return count;
        
    }
 
//*****************************************************************************************************************************************************//
//-----------------------GAME 2------------------------------------------------------------------------------------------------------------------------//
//*****************************************************************************************************************************************************//
    //Game 2 recieves individual bets per digit and calculates the reward accordingly per bet.

    //Run the main game 2 background tasks for efficency
    function backgroundTasks2(uint256 seed) internal returns (uint8,uint8,uint8,uint8,uint8,uint8,uint8) {
        
        uint8 val1;
        uint8 val2;
        uint8 val3;
        uint8 val4;
        uint8 val5;
        uint8 val6;
        
        //Gather random numbers from roll
        (val1,val2,val3,val4,val5,val6) = gatherNumbers(seed);

        //Counts how many numbers are winning numbers.
        uint8 multiCount = multiplierCheck(val1,val2,val3,val4,val5,val6);

        //Returns winning numbers and each individual number winning or not, to main game.
        return (multiCount,val1,val2,val3,val4,val5,val6);
    }

    //Recieves 6 seperate bets for each digit, plus random seed.
    function mainGameTwo(uint256 seed, uint256 val1Bet, uint256 val2Bet, uint256 val3Bet, uint256 val4Bet, uint256 val5Bet, uint256 val6Bet) public payable returns (uint8) {
        require(val1Bet + val4Bet + val4Bet + val4Bet + val4Bet > 10, "Total Bet value must be above 10 Tron.");

        //Gathers results from backgroundtasks2
        (uint8 multiCount,uint8 val1,uint8 val2, uint8 val3, uint8 val4, uint8 val5,uint8 val6) = backgroundTasks2(seed); 

        //Calculates the winnings for each individual bet (6 bets)
       // (uint256 winnings1, uint256 winnings2, uint256 winnings3, uint256 winnings4, uint256 winnings5, uint256 winnings6) = 
      //  calculateActualWinningsGameTwo(multiCount,val1,val2,val3,val4,val5,val6,val1Bet,val2Bet,val3Bet,val4Bet,val5Bet,val6Bet);
        
        // Notify game result
       // emit Game2Result(msg.sender, now, winnings1, winnings2, winnings3, winnings4, winnings5, winnings6); 

        return multiCount;
    }

    function calculateActualWinningsGameTwo(uint8 multiCount,uint8 val1,uint8 val2, uint8 val3, uint8 val4, uint8 val5,uint8 val6,
                                            uint256 val1Bet,uint256 val2Bet,uint256 val3Bet,uint256 val4Bet,uint256 val5Bet,uint256 val6Bet) 
                                            internal returns (uint256,uint256,uint256,uint256,uint256,uint256) {
        //work out winnings 
        //need to change multiplier types to uint256 to extend multiplier number
        
        uint256 val1BetWinnigns = 0;
        uint256 val2BetWinnigns = 0;
        uint256 val3BetWinnigns = 0;
        uint256 val4BetWinnigns = 0;
        uint256 val5BetWinnigns = 0;
        uint256 val6BetWinnigns = 0;

        if (checkResult(val1) == true && val1Bet > 0) {
            val1BetWinnigns = multiplierOne(2) * val1Bet;
        }
        
        if (checkResult(val2) == true && val2Bet > 0) {
            val2BetWinnigns = multiplierTwo(2) * val1Bet;
        }
        
        if (checkResult(val3) == true && val3Bet > 0) {
            val3BetWinnigns = multiplierThree(2) * val1Bet;
        }
        
        if (checkResult(val4) == true  && val4Bet > 0) {
            val4BetWinnigns = multiplierFour(2) * val1Bet;
        }
        
        if (checkResult(val5) == true  && val5Bet > 0) {
            val5BetWinnigns = multiplierFive(2) * val1Bet;
        }
        
        if (checkResult(val6) == true  && val6Bet > 0) {
            val6BetWinnigns = multiplierFive(2) * val1Bet;
        }
    return (val1BetWinnigns,
            val2BetWinnigns,
            val3BetWinnigns,
            val4BetWinnigns,
            val5BetWinnigns,
            val6BetWinnigns);
    }

//*****************************************************************************************************************************************************//
//---------------------  ADMINISTRATION ---------------------------------------------------------------------------------------------------------------//
//*****************************************************************************************************************************************************//
    //Fallback funds recieve function
    function LuckyOne() public payable {}

    function totalTRXbalanceContract()onlyOwner public view returns(uint256){ //check for overflow
        return address(this).balance;
    }

    //transfer TRX and Tokens from contract to owner address
    function manualWithdrawTRX()onlyOwner payable public returns(string memory){
        address(owner).transfer(address(this).balance);
        return "Topia Token and Tron moved to Owner address.";
    }
    
    function manualWithdrawTokens(uint256 tokenAmount)onlyOwner public returns(string memory) { //check for overflow
        bytes memory transferData = abi.encodeWithSignature("transfer(address,uint256)",owner,tokenAmount);
        return "Topia Token Withdraw Succesful.";
    }

    function updateTopiaTokenContractAddress(address _newAddress)onlyOwner public returns(string memory){
        require(_newAddress != address(0), "Invalid Address");
        topiaTokenContractAddress = _newAddress;
        return "Topia Token Contract Address Updated";
    }
    
}

