// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./ITrueCasino.sol";

//import 'hardhat/console.sol';

contract TrueRoulette {
    error SeedMismatch(
        address addr,
        uint256 bets,
        bytes32 sealedSeed,
        bytes32 revealedSeed
    );
    error BetExceedsBalance(address addr, uint256 bets, bytes32 seed, uint256 userBalance, uint256 betNominal);
    error BetExceedsLimits(address addr, uint256 bets, bytes32 seed);
    error SeedSignatureMismatch(bytes32 seed, uint8 v, bytes32 r, bytes32 s);
    event onBetPlaced(address indexed addr, bytes32 indexed seed, uint256 bets);
    event onBetsProcessed(
        address indexed addr,
        bytes32 indexed seed,
        bytes32 revealedSeed,
        uint256 bets,
        uint256 rnd,
        uint256 payout
    );

    ITrueCasino private casino;
    address private owner;

    uint256 constant COMBINATIONS_LENGTH = 151;
    uint256 constant LIQUIDITY_LIMIT=100;
    uint256 constant DECIMALS = 1e18;

    uint40[COMBINATIONS_LENGTH] private outcomes = [
        1,
        2,
        4,
        8,
        16,
        32,
        64,
        128,
        256,
        512,
        1024,
        2048,
        4096,
        8192,
        16384,
        32768,
        65536,
        131072,
        262144,
        524288,
        1048576,
        2097152,
        4194304,
        8388608,
        16777216,
        33554432,
        67108864,
        134217728,
        268435456,
        536870912,
        1073741824,
        2147483648,
        4294967296,
        8589934592,
        17179869184,
        34359738368,
        68719476736,
        6,
        48,
        384,
        3072,
        24576,
        196608,
        1572864,
        12582912,
        100663296,
        805306368,
        6442450944,
        51539607552,
        12,
        96,
        768,
        6144,
        49152,
        393216,
        3145728,
        25165824,
        201326592,
        1610612736,
        12884901888,
        103079215104,
        18,
        144,
        1152,
        9216,
        73728,
        589824,
        4718592,
        37748736,
        301989888,
        2415919104,
        19327352832,
        36,
        288,
        2304,
        18432,
        147456,
        1179648,
        9437184,
        75497472,
        603979776,
        4831838208,
        38654705664,
        72,
        576,
        4608,
        36864,
        294912,
        2359296,
        18874368,
        150994944,
        1207959552,
        9663676416,
        77309411328,
        14,
        112,
        896,
        7168,
        57344,
        458752,
        3670016,
        29360128,
        234881024,
        1879048192,
        15032385536,
        120259084288,
        50,
        400,
        3200,
        25600,
        204800,
        1638400,
        13107200,
        104857600,
        838860800,
        6710886400,
        53687091200,
        100,
        800,
        6400,
        51200,
        409600,
        3276800,
        26214400,
        209715200,
        1677721600,
        13421772800,
        107374182400,
        126,
        1008,
        8064,
        64512,
        516096,
        4128768,
        33030144,
        264241152,
        2113929216,
        16911433728,
        135291469824,
        91625968981,
        45812984490,
        91447186090,
        45991767381,
        524286,
        137438429184,
        8190,
        33546240,
        137405399040,
        19634136210,
        39268272420,
        78536544841
    ];
    uint8[COMBINATIONS_LENGTH] private payouts = [
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        36,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        18,
        9,
        9,
        9,
        9,
        9,
        9,
        9,
        9,
        9,
        9,
        9,
        9,
        9,
        9,
        9,
        9,
        9,
        9,
        9,
        9,
        9,
        9,
        6,
        6,
        6,
        6,
        6,
        6,
        6,
        6,
        6,
        6,
        6,
        2,
        2,
        2,
        2,
        2,
        2,
        3,
        3,
        3,
        3,
        3,
        3
    ];
    struct Bet {
        bytes32 seed;
        uint256 bets;
        bool isOpen;
    }
    mapping(address => Bet) public openBet;

    constructor(address _casinoAddress) {
        casino = ITrueCasino(_casinoAddress);
        owner = msg.sender;
    }

    function getPayoutLimit() public view returns (uint256){
        return casino.getCurrentLiquidity()/LIQUIDITY_LIMIT;
    }

    function getBool(uint256 input, uint256 index)
        internal
        pure
        returns (uint256)
    {
        return (input >> index) & uint256(1);
    }

    function getUint8(uint256 input, uint256 index)
        internal
        pure
        returns (uint256)
    {
        return (input >> (index * 8)) & uint256(255);
    }

    function getBetOutcome(uint256 code, uint256 number)
        internal
        view
        returns (uint256)
    {
        return getBool(outcomes[code], number);
    }

    function getUserBalance(address _addr, bytes32 _revealedSeed)
        public
        view
        returns (uint256, uint256)
    {
        if (!openBet[_addr].isOpen) return (uint256(0), casino.getUserBalance(_addr));
        if (keccak256(abi.encodePacked(_revealedSeed)) != openBet[_addr].seed) {
            revert SeedMismatch(
                _addr,
                openBet[_addr].bets,
                openBet[_addr].seed,
                _revealedSeed
            );
        }
        uint256 payout;
        uint256 rnd = uint256(_revealedSeed) % 37;
        for (uint256 i = 0; i < 32; i += 2) {
            if (getUint8(openBet[_addr].bets, i) == 0) break;
            payout +=
                getUint8(openBet[_addr].bets, i) *
                payouts[getUint8(openBet[_addr].bets, i + 1)] *
                getBetOutcome(getUint8(openBet[_addr].bets, i + 1), rnd);
        }
        return (payout * DECIMALS, casino.getUserBalance(_addr));
    }

    function getOpenSeed(address _addr) public view returns (bytes32) {
        return openBet[_addr].isOpen ? openBet[_addr].seed : bytes32(0);
    }
    function withdrawChips(bytes32 _revealed) public {
        closeBet(_revealed);
        casino.sellChips(msg.sender);
    }
    function closeBet(bytes32 _revealed) public {
        if (openBet[msg.sender].isOpen) {
            if (
                keccak256(abi.encodePacked(_revealed)) !=
                openBet[msg.sender].seed
            ) {
                revert SeedMismatch(
                    msg.sender,
                    openBet[msg.sender].bets,
                    openBet[msg.sender].seed,
                    _revealed
                );
            }
            uint256 rnd = uint256(_revealed) % 37;
            uint256 payout;
            for (uint256 i = 0; i < 32; i += 2) {
                if (getUint8(openBet[msg.sender].bets, i) == 0) break;
                payout +=
                    getUint8(openBet[msg.sender].bets, i) *
                    payouts[getUint8(openBet[msg.sender].bets, i + 1)] *
                    getBetOutcome(
                        getUint8(openBet[msg.sender].bets, i + 1),
                        rnd
                    );
            }
            if (payout > 0) casino.makePayout(msg.sender, payout * DECIMALS);
            emit onBetsProcessed(
                msg.sender,
                openBet[msg.sender].seed,
                _revealed,
                openBet[msg.sender].bets,
                rnd,
                payout
            );
            openBet[msg.sender].isOpen = false;
        }
    }

    function checkSignature(
        bytes32 _seed,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal view {
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _seed)
        );
        address addr = ecrecover(messageDigest, _v, _r, _s);
        if (addr != owner) {
            revert SeedSignatureMismatch(_seed, _v, _r, _s);
        }
    }

    function placeBet(
        bytes32 _newSeed,
        uint256 _bets,
        bytes32 _prevRevealedSeed,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        checkSignature(_newSeed, _v, _r, _s);
        closeBet(_prevRevealedSeed);
        uint256 nominal;
        for (uint256 i = 0; i < 32; i += 2) {
            if (getUint8(_bets, i) == 0) break;
            nominal += getUint8(_bets, i);
        }
        uint256 userBalance = casino.getUserBalance(msg.sender);
        if (nominal * DECIMALS > userBalance) {
            revert BetExceedsBalance({
                addr: msg.sender,
                bets: _bets,
                seed: _newSeed,
                userBalance: userBalance,
                betNominal: nominal*DECIMALS
            });
        }
        casino.makeDeposit(msg.sender, nominal * DECIMALS);
        openBet[msg.sender] = Bet(_newSeed, _bets, true);
        emit onBetPlaced(msg.sender, _newSeed, _bets);
    }
}
