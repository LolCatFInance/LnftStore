// SPDX-License-Identifier: GNU
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IERC721Receiver.sol";
import "./SafeERC20.sol";
contract LcatNftStore is Ownable,ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC721 public Lnft;
    IERC20 public Lcat;
    uint256 public TotalItems;
    uint256 public TotalRemovedItems;
    mapping(uint256=>uint256)public NftToItemId;
    event NewItem(uint256 indexed ItemId,uint256 indexed TokenId,uint256 indexed TokenPrice);
    event DeleteItem(uint256 indexed ItemId);
    event TokenSold(uint256 indexed TokenId,uint256 indexed SellPrice,address indexed Customer);
    struct Item{
        uint256 ItemId;
        uint256 TokenId;
        uint256 SellPrice;
        bool Issold;
        bool Removed;
        }
        Item[] public Items;
   function SetLnftAddress(IERC721 LnftAddress )public onlyOwner{
      Lnft=IERC721(LnftAddress); 
   }
   function setLcatAddress(IERC20 LcatAddress)public onlyOwner{
       Lcat=IERC20(LcatAddress);
   }
   function AddItem(uint256 TokenId,uint256 TokenPrice)public onlyOwner{
       Items.push(Item(TotalItems,TokenId,TokenPrice,false,false));
       NftToItemId[TokenId]=Items.length.sub(1);
       Lnft.safeTransferFrom(msg.sender,address(this),TokenId);
       TotalItems++;
       emit NewItem(TotalItems,TokenId,TokenPrice);
   }
   function RemoveItem(uint256 ItemId)public onlyOwner{
       Item memory MyItem=Items[ItemId];
       if(MyItem.Issold!=true){
       Lnft.safeTransferFrom(address(this),msg.sender,Items[ItemId].TokenId);
       }
       MyItem.Issold=true;
       MyItem.Removed=true;
       TotalRemovedItems++;
       emit DeleteItem(ItemId);
       
   }
   function BuyNft(uint256 ItemId)public nonReentrant {
       Item storage MyItem=Items[ItemId];
       require(MyItem.Issold==false,"IeamSoldPreviously");
       Lcat.safeTransferFrom(msg.sender,address(this),MyItem.SellPrice);
       Lnft.safeTransferFrom(address(this),msg.sender,MyItem.TokenId);
       MyItem.Issold=true;
       emit TokenSold(MyItem.TokenId,MyItem.SellPrice,msg.sender);
   }
   function CollectLcat() public onlyOwner{
       Lcat.safeTransfer(msg.sender,Lcat.balanceOf(address(this)));
   }
   function TotalIteams() public view returns(uint256){
      uint256 IteamCount=TotalItems.sub(TotalRemovedItems);
      return IteamCount;
   }
   function RescueBep20(IERC20 TokenAddress,uint256 Amount,address To)public onlyOwner{
       IERC20(TokenAddress).safeTransfer(To,Amount);
   }
   function RescueErc721(IERC721 NftContract,uint256 TokenId,address To)public onlyOwner{
       require(NftContract!=Lnft);
       IERC721(NftContract).safeTransferFrom(address(this),To,TokenId);
   }
     function onERC721Received(address, address, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
   
   
}
