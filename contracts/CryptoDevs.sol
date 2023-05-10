// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWhitelist.sol";

contract CryptoDevs is ERC721Enumerable, Ownable {
    // baseURI + TokenId
    string _baseTokenURI;

    // token 가격
    uint256 public _price = 0.01 ether;
    
    // 컨트랙트 긴급 중지
    bool public _paused;

    // 최대 민팅가능한 토큰 개수
    uint256 public maxTokenIds = 20;

    // 민팅된 토큰 ids
    uint256 public tokenIds;

    // whitelist 컨트랙트 인스턴스
    IWhitelist whitelist;

    // 사전 판매가 시작되었는지 여부
    bool public presalStated;

    // 사전 판매 종료 시점 타임스탬프
    uint256 public presaleEnded;

    

    // 계약이 중지가 되었는지를 확인하는 수정자
      modifier onlyWhenNotPaused {
        require(!_paused, "Contract currently paused");
        _;
    }

    constructor (string memory baseURI, address whitelistContract) ERC721("Crypto Devs", "CD") {
        _baseTokenURI = baseURI;
        whitelist = IWhitelist(whitelistContract);
    }

    function startPresale() public onlyOwner{
        presalStated = true;

        presaleEnded = block.timestamp + 5 minutes;
    }

    function presaleMint() public payable onlyWhenNotPaused {
        require(presalStated && block.timestamp < presaleEnded, "Presale is not running");
        require(whitelist.whitelistedAddressess(msg.sender), "You are not whitelisted");
        require(tokenIds < maxTokenIds, "Exceeded maximum Crypto Devs supply");
        require(msg.value >= _price, "Ether sent is not correct");
        tokenIds += 1;
        _safeMint(msg.sender, tokenIds);
    }

    function mint() public payable onlyWhenNotPaused {
        require(presalStated && block.timestamp >= presaleEnded, "Presale has not ended yet");
        require(tokenIds < maxTokenIds, "Exceed maximum Crypto Devs supply");
        require(msg.value >= _price, "Ether sent is not correct");
        tokenIds += 1;
        _safeMint(msg.sender, tokenIds);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setPaused(bool val) public onlyOwner {
        _paused = val;
    }
    
    function withdraw() public onlyOwner {
        address _owner =  owner();
        uint256 amount = address(this).balance;
        (bool sent,) = _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}

    fallback() external payable {}
}