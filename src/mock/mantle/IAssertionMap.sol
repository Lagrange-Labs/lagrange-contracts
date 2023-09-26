// SPDX-License-Identifier: Apache-2.0

/*
 * Modifications Copyright 2022, Specular contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.12;

interface IAssertionMap {

    function getStateHash(uint256 assertionID) external view returns (bytes32);

    function getInboxSize(uint256 assertionID) external view returns (uint256);

    function getParentID(uint256 assertionID) external view returns (uint256);

    function getDeadline(uint256 assertionID) external view returns (uint256);

    function getProposalTime(uint256 assertionID) external view returns (uint256);

    function getNumStakers(uint256 assertionID) external view returns (uint256);
}