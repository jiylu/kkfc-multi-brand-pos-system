# STSWENG Group 02 Masterfile — Multi-brand POS

## Diagrams provided by the client

These diagrams describe intended future (TO-BE) workflows, not verified existing processes. They are not automatically approved MVP requirements.

> Accounting content is excluded from this conversion. Source pages 6–8 (expense accounting, platform commissions/settlements, and brand revenue/direct-cost accounting) are omitted. Financial branches in purchasing and dine-in are also omitted; the retained operational paths are connected directly.

## 1. Purchasing and receiving

Source: page 1. This is the ideal purchase process and recording flow the client wants the team to follow once the system exists, rather than the existing process.

```mermaid
flowchart TD
    A["Count raw materials and prepared inventory: Kitchen / Storekeeper"] --> B["Reconcile physical counts with system balances; record expiry, waste and discrepancies"]
    B --> C["Calculate purchase requirements: demand + buffer - usable stock - incoming orders"]
    C --> D["Prepare purchase request: item, specification, quantity and required date"]
    D --> E["Review stock need: Kitchen Head"]
    E --> F{"Purchase request approved by authorized approver?"}
    F -->|Revise| D
    F -->|Yes| G{"Purchase source?"}
    G -->|Supplier| H["Compare quotations and terms; select supplier"]
    H --> I["Prepare, authorize and release purchase order; confirm quantities and delivery date"]
    I --> J["Send purchase order to supplier; obtain confirmation"]
    J --> K["Supplier delivers raw materials"]
    G -->|Direct market purchase| L["Release approved market purchase order/list; set item quantities"]
    L --> M["Buyer purchases from market; collect purchase details"]
    M --> N["Transport purchases to kitchen"]
    K --> O["Receive and inspect materials; count/weigh and check quality, expiry and condition"]
    N --> O
    O --> P{"Matches approved order and acceptable quality?"}
    P -->|No| Q["Document shortage or damage; hold affected items and arrange return or resolution"]
    Q --> R["Obtain approval for changes if needed; reinspect replacements or corrected delivery"]
    R --> O
    P -->|Yes| S["Issue signed receiving report; record actual accepted quantities and batches"]
    S --> T["Label and store materials; update shared inventory using actual receipts"]
```

The source phrase “incoming orders” remains undefined; this conversion does not choose whether it means supplier supply or customer demand.

## 2. Production process

Source: page 2. Raw-material issue, preparation, QC, accepted conversion and demand-guidance feedback remain distinct.

```mermaid
flowchart TD
    A{"Sufficient usable raw materials?"} -->|No| B["Generate purchase request for shortages; follow purchasing and receiving process"]
    B --> C["Update inventory after accepted delivery"]
    C --> D["Calculate raw materials required; include expected yields and added ingredients"]
    D --> E{"Production plan approved?"}
    E -->|Yes| A
    A -->|Yes| F["Release production order; assign preparer, checker and source batches"]
    F --> G["Issue and weigh raw materials; record actual quantities moved into preparation"]
    G --> H["Prepare derivatives: trim, cut, marinate or otherwise process"]
    H --> I["Weigh and pack standard portions; record output, usable leftovers and losses"]
    I --> J["Check quality, portion weights and yield; reconcile inputs against actual outputs"]
    J --> K{"Batch accepted?"}
    K -->|No| L["Hold and investigate; record approved rework, corrections or disposal"]
    L --> J
    K -->|Yes| M["Confirm inventory conversion; reduce preparation stock and add accepted derivatives"]
    M --> N["Label and store portions: batch ID, weight, preparation time and use-by"]
    N --> O["POS compares recommended versus actual output; flag shortages, excess preparation and availability"]
    O --> P["Feed sales, stockouts and waste into the next forecast"]
    P --> Q["Analyze sales across brands/channels: history, meal periods, trends and planned promotions"]
    Q --> R["Forecast menu-item demand for the next production period"]
    R --> S["Convert forecast sales into preparation needs using approved recipes, portion sizes and yields"]
    S --> T["Check shared prepared inventory: usable portions, expiry, reservations and work in progress"]
    T --> U["Recommend production quantities: derivative, portion size, pack count and required time"]
    U --> V["Kitchen Head reviews recommendations; confirm demand assumptions, shelf life and kitchen capacity"]
    V --> E
    E -->|Revise| W["Adjust quantities or timing; record override reason"]
    W --> V
```

## 3. Kitchen preparation and fulfillment

Source: page 3. The client caption says “Assuming with API integration.”

```mermaid
flowchart TD
    A["Receive confirmed kitchen ticket: GrabFood, foodpanda, dine-in or phone"] --> B["Kitchen acknowledges ticket; record start time and assigned station"]
    B --> C["Prepare using approved recipes and portions; record actual ingredient consumption"]
    C --> D["Plate or pack food; include sides, sauces, drinks and utensils as required"]
    D --> E["Checker matches completed food to ticket; verify items, quantities, modifiers and quality"]
    E --> F{"Complete and correct?"}
    F -->|No| G["Correct missing or incorrect items; record rework and waste where applicable"]
    G --> E
    F -->|Yes| H["Confirm completed order; record checker and ready time"]
    H --> I{"Fulfillment route?"}
    I -->|Online platform / phone delivery| J["Proceed to photo documentation and dispatch"]
    I -->|Phone pickup| K["Proceed to pickup verification and handover"]
    I -->|Dine-in| L["Serve correct table; confirm items served and update open check"]
```

## 4. Delivery-platform ordering without API integration

Source: page 4. The source includes OCR/image extraction, photo evidence and separate READY confirmations. These are client-intended steps; their presence here does not change the PRD's proposed deferrals.

### 4.1 Capture and verify the order

```mermaid
flowchart TD
    A["Receive and accept order in GrabFood or foodpanda merchant app"] --> B["Photograph complete order details; capture additional images for long orders"]
    B --> C["Upload images to POS; select GrabFood or foodpanda"]
    C --> D["System extracts order ID, items, quantities, modifiers, notes and amounts"]
    D --> E["Check duplicate order using platform, store and order ID"]
    E --> F{"Order already exists?"}
    F -->|Yes| G["Open existing order; attach images without creating another sale"]
    F -->|No| H["Match captured items to POS menu and recipes; highlight unclear or unmatched details"]
    H --> I["Team reviews extracted order beside source image; confirm completeness and correct exceptions"]
    I --> J{"Details verified?"}
    J -->|No| K["Retake image or correct flagged fields"]
    K --> I
    J -->|Yes| L["Confirm POS order; record verification timestamp and staff member"]
    L --> M["Generate kitchen ticket; link platform order ID and source images"]
```

### 4.2 Prepare, confirm READY and dispatch

Continues from the verified kitchen ticket in §4.1. The financial receipt component of the source's “POS order receipt and kitchen ticket” node is omitted.

```mermaid
flowchart TD
    A["Verified kitchen ticket"] --> B["Reserve ingredients and prepare order; record preparation start and actual consumption"]
    B --> C["Check completed food against verified ticket; confirm items, portions, modifiers and quality"]
    C --> D{"Complete and correct?"}
    D -->|No| E["Correct order and record rework"]
    E --> C
    D -->|Yes| F["Photograph prepared food; pack, seal, label and photograph all bags"]
    F --> G["Mark READY FOR PICKUP in POS; automatically capture POS timestamp and staff"]
    G --> H["Mark READY FOR PICKUP in platform app; team performs separate app confirmation"]
    H --> I["Confirm platform action in POS; attach screenshot or photo of app confirmation"]
    I --> J["Record platform confirmation evidence; save visible app timestamp and POS logging time"]
    J --> K{"Both ready confirmations recorded?"}
    K -->|No| L["Flag missing confirmation; complete action or document supervisor-approved exception"]
    L --> M["Verify arriving rider and order ID; check all bags together"]
    K -->|Yes| M
    M --> N["Rider photographs receiving the order; record acknowledgement and available photo evidence"]
    N --> O["Confirm dispatch in POS and platform app as required by platform workflow"]
    O --> P["Record handover timestamp and staff; archive order, photos and confirmation history"]
```

## 5. Dine-in ordering and service

Source: page 5. Billing, payments, account charges, invoices, financial closure and related correction branches are omitted. Operational table checks and amendment history are retained.

```mermaid
flowchart TD
    A["Receive dine-in customer; open table check in POS"] --> B["Record table number, guest count and server"]
    B --> C["Take order: items, quantities, modifiers and instructions"]
    C --> D["Check availability; read back order and requests with customer"]
    D --> E["Confirm order in POS; record timestamp and send kitchen ticket"]
    E --> F["Kitchen acknowledges and prepares; reserve stock and record actual consumption"]
    F --> G["Check food quality and order accuracy"]
    G --> H["Serve food to correct table; record each item as served or pending"]
    H --> I{"Customer requests changes or additional items?"}
    I -->|Yes| J["Open existing table check; record addition, modification, cancellation or table transfer"]
    J --> K{"Type of change?"}
    K -->|Add or modify| L["Check availability and preparation status; confirm revised items with customer"]
    L --> M["Send kitchen amendment; clearly identify new or changed items"]
    M --> F
    K -->|Cancel or remove| N["Check whether preparation has started; obtain required approval and record reason"]
    N --> O["Notify kitchen and update operational check; release unused stock or record actual waste"]
    K -->|Transfer or split table check| P["Confirm destination table/check; move entries without duplicating kitchen orders"]
    O --> Q["Keep original entries and amendment history"]
    P --> Q
    Q --> H
    H --> R{"Any unserved or unresolved items?"}
    R -->|Yes| S["Resolve with customer; serve pending items or approve removal"]
    S --> T["Update service status"]
    T --> R
    R -->|No| U["Confirm service completion; record server and timestamp"]
```
