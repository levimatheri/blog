---
title: Swap Nodes In Pairs
tags:
  - Linked lists
  - Recursion
  - Code challenge
---

It's been a while since I looked at some coding challenges, so I decided to tackle a fun problem. The problem can be found in [Leetcode](https://leetcode.com/problems/swap-nodes-in-pairs/), one of the most popular coding practice platforms. It has a ton of problems, majority of which have been asked in technical interviews at top tech companies like FAANG (Facebook, Amazon, Apple, Netflix, Google), and Microsoft. 

Here's the problem statement:

_Given a linked list, swap every two adjacent nodes and return its head. You must solve the problem without modifying the values in the list's nodes (i.e., only nodes themselves may be changed.)_

<div class="card mb-3">
    <img class="card-img-top" src="https://raw.githubusercontent.com/levimatheri/blog/main/_includes/images/swap_ex1.jpg"/>
    <div class="card-body bg-light">
        <div class="card-text">
            Example
        </div>
    </div>
</div>

The problem states that we cannot modify the values of the list nodes themselves, otherwise the solution would be too easy!
We also, of course, cannot just create a new auxiliary list. Creating an auxiliary list would incur `O(n)` space complexity. We must swap the nodes in the linked list given, i.e. `O(1)` space complexity.

Two ideas on how to solve this come to mind:
1. _Iterative_: Consider each pair and rewire the second node's `next` pointer to point to the first node. Maintain a previous and a next pointer reference in order to stitch nodes together
2. _Recursive_: Recurse through each pair, each time passing the first node of the next pair, until you get to the end, then rewire nodes as you traverse the call stack.

We need to be careful about odd numbered lists e.g. `1 -> 2 -> 3`, as well as making sure we do not introduce cycles in the list as we rewire nodes.

Below is my iterative and recursive solutions in Java, with comments to explain what's going on:

*Iterative*

```java
ListNode swapPairsIterative(ListNode head) {
    // maintain a dummy node since the head will change when we swap nodes
    ListNode dummy = new ListNode();
    ListNode prev = dummy;
    dummy.next = head;
    ListNode curr = head;
    while (curr != null && curr.next != null) {
        // store reference to next pair
        ListNode next = curr.next.next;
        // store reference to the node that will be first in current pair
        ListNode newCurr = curr.next;
        // swap pair nodes
        curr.next.next = curr;
        // dereference next pointer to avoid cycles
        curr.next = null;
        // rewire previous pair with current pair
        prev.next = newCurr;
        prev = curr;
        curr = next;
    }
    
    // handle tail of odd numbered lists
    if (curr == null || curr.next == null) prev.next = curr;
    
    return dummy.next;
}
```

*Recursive*
```java
ListNode swapPairsRecursive(ListNode head) {
    // base case
    if (head == null || head.next == null) return head;
    ListNode nextPairHead = swapPairsRecursive(head.next.next);
    // swap pair nodes
    ListNode newPairHead = head.next;
    head.next.next = head;
    // dereference next pointer to avoid cycles
    head.next = null;
    // rewire previous pair with current pair
    head.next = nextPairHead;
    return newPairHead;
}
```
As you can see the recursive approach a bit more cleaner, but the iterative is not too bad either. Both have `O(n)` time complexity since we're visiting each node once, and `O(1)` space complexity since we're modifying the list in-place.

Thanks for reading, and happy coding!