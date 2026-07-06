# Application Requirements: Fulfilment Operator

## Purpose

The Fulfilment Operator application supports warehouse fulfilment users who view released orders, identify required components, pick, pack, purchase courier shipping where authorized, print labels, and complete or partially fulfil orders. This workload crosses Order Fulfilment, Sales, Inventory Management, and courier integration.

## Application Boundary

| Item | Value |
|---|---|
| UI | `Acme.Erp.FulfilmentOperator.Ui` |
| API | `Acme.Erp.FulfilmentOperator.Api` |
| Primary users | Fulfilment Operator |
| Database | None |
| Domain APIs consumed | Order Fulfilment, Sales, Inventory Management |

The Fulfilment Operator UI calls only the Fulfilment Operator API. The Fulfilment Operator API does not own durable state, does not use EF Core, and does not connect to SQL Server.

## User-Facing Scope

- Display released fulfilment tasks and required order details.
- Show products, SKUs, quantities, availability, and component information required for fulfilment.
- Capture picked products, picked quantities, pack confirmation, shipping purchase inputs, label printing action, and completion action.
- Surface pick exceptions, damaged components, short picks, shipping purchase failures, label failures, and inventory consumption exceptions.
- Support partial fulfilment where allowed by Order Fulfilment.
- Display customer delivery context only where required for fulfilment and allowed by privacy policy.

## Functional Requirements

| ID | Requirement |
|---|---|
| FOP-APP-001 | The application shall display released fulfilment tasks from Order Fulfilment within the agreed response threshold. |
| FOP-APP-002 | The application shall show component requirements and inventory validation data without storing sales or inventory state locally. |
| FOP-APP-003 | The application shall allow operators to record picked components through Order Fulfilment. |
| FOP-APP-004 | The application shall display pick validation results and exception state returned by Order Fulfilment. |
| FOP-APP-005 | The application shall allow authorized operators to pack orders, request courier shipping purchase, print PDF/browser labels, and complete orders through Order Fulfilment. |
| FOP-APP-006 | The application shall route exception approval, completion reversal, and cancellation-after-picking approval to supervisor applications. |
| FOP-APP-007 | The application shall provide accessible fulfilment task entry and review screens. |

## Security and Audit

Order Fulfilment remains authoritative for fulfilment state, courier records, label references, completion decisions, exception state, and audit history. Inventory Management remains authoritative for stock balances, reservations, consumption, and reversals.
