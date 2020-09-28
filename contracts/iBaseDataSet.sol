pragma solidity >= 0.4.24;

interface IBaseDataSet{
    function transferManager(address _newManager) external;
    function getVeDIDHubAddress() external view returns(address);
    function getManagerOfAddress() external view returns(address);
    function getManagerOfVeDID() external view returns(bytes32);
    function registerToVeDIDHub() external;
}