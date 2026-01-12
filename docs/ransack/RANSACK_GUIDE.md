# Ransack Search & Filter Guide

## Table of Contents

- [Overview](#overview)
- [Setup](#setup)
- [Security Configuration](#security-configuration)
- [Search Predicates](#search-predicates)
- [Controller Implementation](#controller-implementation)
- [View Implementation](#view-implementation)
- [Advanced Usage](#advanced-usage)
- [Troubleshooting](#troubleshooting)

---

## Overview

**Ransack** is a powerful Ruby gem that enables object-based searching and filtering. It provides:

- Simple search forms
- Advanced filtering capabilities
- Sorting functionality
- Database-agnostic querying

**Gem**: `ransack` (already in Gemfile)

---

## Setup

### 1. Installation

Ransack is already included in the `Gemfile`:

```ruby
gem 'ransack'
```

### 2. Controller Setup

Include Ransack in your controller's index action:

```ruby
def index
  @q = policy_scope(Worker).ransack(params[:q])
  @pagy, @workers = pagy(@q.result, limit: per_page)
end
```

**Key Points:**

- `ransack(params[:q])` - Creates a search object from query parameters
- `@q.result` - Returns the filtered ActiveRecord relation
- Works seamlessly with Pundit's `policy_scope` and Pagy pagination

---

## Security Configuration

### ⚠️ **CRITICAL: Ransackable Attributes Whitelist**

Ransack requires explicit whitelisting of searchable attributes and associations for security.

### Model Configuration

Add these class methods to your model:

```ruby
class Worker < ApplicationRecord
  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[
      id
      name
      worker_type
      gender
      is_active
      hired_date
      nationality
      identity_number
      created_at
      updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[
      work_order_workers
      work_orders
      pay_calculation_details
      pay_calculations
    ]
  end
end
```

### Why This Matters:

**Without whitelisting:**

```
Ransack::ConfigurationError: Attribute 'name' is not whitelisted
```

**Security Risk Without Whitelisting:**

```ruby
# Malicious attempts would be possible:
?q[password_digest_cont]=...  # Try to search passwords
?q[secret_token_eq]=...        # Try to access tokens
?q[encrypted_data_matches]=... # Try to access sensitive data
```

**With whitelisting:**
Only explicitly allowed attributes can be searched. Everything else is rejected.

---

## Search Predicates

Ransack uses predicates (suffixes) to define search types:

### Common Predicates

| Predicate   | Description                 | Example                      | SQL Equivalent                      |
| ----------- | --------------------------- | ---------------------------- | ----------------------------------- |
| `_eq`       | Equals (exact match)        | `worker_type_eq=Full - Time` | `WHERE worker_type = 'Full - Time'` |
| `_not_eq`   | Not equals                  | `is_active_not_eq=false`     | `WHERE is_active != false`          |
| `_cont`     | Contains (case-insensitive) | `name_cont=John`             | `WHERE name ILIKE '%John%'`         |
| `_not_cont` | Does not contain            | `name_not_cont=Test`         | `WHERE name NOT ILIKE '%Test%'`     |
| `_start`    | Starts with                 | `name_start=John`            | `WHERE name ILIKE 'John%'`          |
| `_end`      | Ends with                   | `name_end=Smith`             | `WHERE name ILIKE '%Smith'`         |
| `_present`  | Is not null                 | `hired_date_present=1`       | `WHERE hired_date IS NOT NULL`      |
| `_blank`    | Is null                     | `hired_date_blank=1`         | `WHERE hired_date IS NULL`          |
| `_null`     | Is null                     | `hired_date_null=1`          | `WHERE hired_date IS NULL`          |
| `_not_null` | Is not null                 | `hired_date_not_null=1`      | `WHERE hired_date IS NOT NULL`      |
| `_in`       | In array                    | `id_in[]=1&id_in[]=2`        | `WHERE id IN (1, 2)`                |
| `_not_in`   | Not in array                | `id_not_in[]=1`              | `WHERE id NOT IN (1)`               |

### Date/Number Comparisons

| Predicate | Description           | Example                      | SQL Equivalent                     |
| --------- | --------------------- | ---------------------------- | ---------------------------------- |
| `_gt`     | Greater than          | `hired_date_gt=2020-01-01`   | `WHERE hired_date > '2020-01-01'`  |
| `_gteq`   | Greater than or equal | `hired_date_gteq=2020-01-01` | `WHERE hired_date >= '2020-01-01'` |
| `_lt`     | Less than             | `hired_date_lt=2020-01-01`   | `WHERE hired_date < '2020-01-01'`  |
| `_lteq`   | Less than or equal    | `hired_date_lteq=2020-01-01` | `WHERE hired_date <= '2020-01-01'` |

### Boolean Predicates

| Predicate | Description | Example             |
| --------- | ----------- | ------------------- |
| `_true`   | Is true     | `is_active_true=1`  |
| `_false`  | Is false    | `is_active_false=1` |

---

## Controller Implementation

### Basic Implementation

```ruby
class WorkersController < ApplicationController
  def index
    authorize Worker

    @q = policy_scope(Worker).ransack(params[:q])
    per_page = params[:per_page].present? ? params[:per_page].to_i : 10
    @pagy, @workers = pagy(@q.result, limit: per_page)
  end
end
```

### Advanced Implementation with Default Sort

```ruby
def index
  authorize Worker

  # Apply ransack with default sort
  @q = policy_scope(Worker).ransack(params[:q])
  @q.sorts = 'created_at desc' if @q.sorts.empty?

  per_page = params[:per_page].present? ? params[:per_page].to_i : 10
  @pagy, @workers = pagy(@q.result, limit: per_page)
end
```

### With Custom Scopes

```ruby
def index
  authorize Worker

  # Start with a custom scope
  base_scope = policy_scope(Worker).active_workers

  @q = base_scope.ransack(params[:q])
  per_page = params[:per_page].present? ? params[:per_page].to_i : 10
  @pagy, @workers = pagy(@q.result, limit: per_page)
end
```

---

## View Implementation

### Search Form

```erb
<%= search_form_for @q, html: { class: 'mb-3' } do |f| %>
  <div class="row g-2">
    <!-- Text Search -->
    <div class="col-md-2">
      <%= f.search_field :id_eq,
          class: 'form-control form-control-sm',
          placeholder: 'Search Work ID..' %>
    </div>

    <div class="col-md-2">
      <%= f.search_field :name_cont,
          class: 'form-control form-control-sm',
          placeholder: 'Search Worker Name..' %>
    </div>

    <!-- Select Dropdown -->
    <div class="col-md-2">
      <%= f.select :worker_type_eq,
          options_for_select([['Part - Time', 'Part - Time'], ['Full - Time', 'Full - Time']],
                             f.object.worker_type_eq),
          { include_blank: 'Select Worker Type..' },
          { class: 'form-select form-select-sm' } %>
    </div>

    <!-- Boolean Select -->
    <div class="col-md-2">
      <%= f.select :is_active_eq,
          options_for_select([['Active', true], ['Inactive', false]],
                             f.object.is_active_eq),
          { include_blank: 'Select Status..' },
          { class: 'form-select form-select-sm' } %>
    </div>

    <!-- Date Field -->
    <div class="col-md-2">
      <%= f.date_field :hired_date_eq,
          class: 'form-control form-control-sm',
          placeholder: 'Select Hired Date' %>
    </div>

    <!-- Submit & Reset -->
    <div class="col-md-2 d-flex gap-1">
      <%= f.submit 'Search', class: 'btn btn-success btn-sm flex-grow-1' %>
      <%= link_to 'Reset', workers_path, class: 'btn btn-secondary btn-sm flex-grow-1' %>
    </div>
  </div>
<% end %>
```

### Sortable Table Headers

```erb
<thead class="table-success">
  <tr>
    <th class="text-center">
      <%= sort_link(@q, :id, 'Worker ID', default_order: :asc) %>
    </th>
    <th>
      <%= sort_link(@q, :name, 'Worker Name', default_order: :asc) %>
    </th>
    <th>
      <%= sort_link(@q, :worker_type, 'Worker Type', default_order: :asc) %>
    </th>
    <th class="text-center">
      <%= sort_link(@q, :is_active, 'Status', default_order: :desc) %>
    </th>
    <th class="text-center">
      <%= sort_link(@q, :hired_date, 'Hired Date', default_order: :desc) %>
    </th>
    <th class="text-center">Actions</th>
  </tr>
</thead>
```

**Sort Link Options:**

- `default_order: :asc` - Initial sort direction
- `default_order: :desc` - Initial sort direction (descending)
- Multiple sorts: `sort_link(@q, [:name, :created_at], 'Name & Date')`

---

## Advanced Usage

### 1. Date Range Search

```erb
<!-- View -->
<div class="col-md-3">
  <%= f.label :hired_date_gteq, "Hired From" %>
  <%= f.date_field :hired_date_gteq, class: 'form-control form-control-sm' %>
</div>

<div class="col-md-3">
  <%= f.label :hired_date_lteq, "Hired Until" %>
  <%= f.date_field :hired_date_lteq, class: 'form-control form-control-sm' %>
</div>
```

**URL Example:**

```
?q[hired_date_gteq]=2020-01-01&q[hired_date_lteq]=2023-12-31
```

### 2. Multiple Select (IN query)

```erb
<!-- View -->
<%= f.select :id_in,
    options_for_select(Worker.pluck(:id, :name), f.object.id_in),
    { include_blank: 'Select Workers..' },
    { multiple: true, class: 'form-select form-select-sm' } %>
```

**URL Example:**

```
?q[id_in][]=1&q[id_in][]=2&q[id_in][]=3
```

### 3. Association Search

```erb
<!-- Search by related work_order status -->
<%= f.select :work_orders_work_order_status_eq,
    options_for_select(['ongoing', 'pending', 'completed'],
                       f.object.work_orders_work_order_status_eq),
    { include_blank: 'Work Order Status..' },
    { class: 'form-select form-select-sm' } %>
```

### 4. OR Conditions

```ruby
# Controller
@q = Worker.ransack(params[:q])

# Search name OR identity_number
# URL: ?q[name_or_identity_number_cont]=John
```

```erb
<!-- View -->
<%= f.search_field :name_or_identity_number_cont,
    class: 'form-control',
    placeholder: 'Search Name or ID Number' %>
```

### 5. Custom Predicates

```ruby
# config/initializers/ransack.rb
Ransack.configure do |config|
  # Add custom predicates here if needed
  config.add_predicate 'recent',
    arel_predicate: 'gt',
    formatter: proc { |v| 30.days.ago }
end
```

---

## Combining with Pagy

### Preserve Search Parameters in Pagination

```erb
<!-- Per-page selector preserving search params -->
<%= form_with url: workers_path, method: :get, local: true, html: { class: 'd-inline' } do |f| %>
  <% params[:q]&.each do |key, value| %>
    <%= hidden_field_tag "q[#{key}]", value %>
  <% end %>

  <%= f.select :per_page,
      options_for_select([10, 25, 50, 100], params[:per_page] || 10),
      {},
      { class: 'form-select form-select-sm d-inline-block',
        style: 'width: auto;',
        onchange: 'this.form.submit()' } %>
<% end %>
```

---

## Troubleshooting

### Common Issues

#### 1. "Attribute is not whitelisted"

**Error:**

```
Ransack needs a whitelist of attributes for searching
```

**Solution:**
Add the attribute to `ransackable_attributes` in your model.

#### 2. Search Not Working

**Check:**

1. Is `@q` passed to the view? (`@q = Model.ransack(params[:q])`)
2. Is the form using `search_form_for @q`?
3. Are attributes whitelisted in the model?
4. Check the generated SQL in logs: `@q.result.to_sql`

#### 3. Sort Not Working

**Check:**

1. Is the attribute in `ransackable_attributes`?
2. Is `sort_link` using `@q` object?
3. Check browser URL for sort parameters: `?q[s]=name+asc`

#### 4. Association Search Not Working

**Check:**

1. Is the association in `ransackable_associations`?
2. Is the association properly defined in the model?
3. Use proper syntax: `association_name_attribute_predicate`

---

## URL Examples

### Simple Searches

```bash
# Exact match
/workers?q[worker_type_eq]=Full - Time

# Contains (case-insensitive)
/workers?q[name_cont]=john

# Boolean
/workers?q[is_active_eq]=true
```

### Combined Searches

```bash
# Multiple conditions (AND)
/workers?q[name_cont]=john&q[worker_type_eq]=Full - Time&q[is_active_eq]=true

# With sorting
/workers?q[name_cont]=john&q[s]=created_at+desc

# With pagination
/workers?q[name_cont]=john&page=2&per_page=25
```

### Date Ranges

```bash
# Hired between dates
/workers?q[hired_date_gteq]=2020-01-01&q[hired_date_lteq]=2023-12-31

# Hired in last year
/workers?q[hired_date_gteq]=2024-01-01
```

---

## Best Practices

### 1. Always Whitelist Attributes

Never skip the `ransackable_attributes` method. It's your security layer.

### 2. Use Appropriate Predicates

- `_eq` for dropdowns and exact matches
- `_cont` for text searches
- `_gteq`/`_lteq` for date ranges

### 3. Provide Clear Placeholders

```erb
<%= f.search_field :name_cont, placeholder: 'Search by name...' %>
```

### 4. Add Reset Button

Always provide a way to clear filters:

```erb
<%= link_to 'Reset', workers_path, class: 'btn btn-secondary' %>
```

### 5. Preserve Search State

When changing per-page or navigating, preserve search parameters.

### 6. Test Your Searches

```ruby
# spec/requests/workers_spec.rb
it "filters workers by name" do
  create(:worker, name: "John Doe")
  create(:worker, name: "Jane Smith")

  get workers_path, params: { q: { name_cont: "John" } }

  expect(response.body).to include("John Doe")
  expect(response.body).not_to include("Jane Smith")
end
```

---

## Performance Tips

### 1. Add Database Indexes

```ruby
# db/migrate/xxx_add_indexes_to_workers.rb
add_index :workers, :name
add_index :workers, :worker_type
add_index :workers, :is_active
add_index :workers, :hired_date
```

### 2. Use Includes for Associations

```ruby
@q = Worker.includes(:work_orders).ransack(params[:q])
```

### 3. Limit Searchable Attributes

Only whitelist attributes that actually need to be searchable.

---

## References

- [Ransack GitHub](https://github.com/activerecord-hackery/ransack)
- [Ransack Demo App](https://ransack-demo.herokuapp.com/)
- [Predicates List](https://github.com/activerecord-hackery/ransack#search-matchers)

---

## Support

For issues or questions:

1. Check the [Ransack Wiki](https://github.com/activerecord-hackery/ransack/wiki)
2. Review the [Demo Application](https://ransack-demo.herokuapp.com/)
3. Search [Stack Overflow](https://stackoverflow.com/questions/tagged/ransack)
