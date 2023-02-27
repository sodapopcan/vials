# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  export: [
    locals_without_parens: [
      create: 2,
      edit: 2,
      remove: 1,
      base_path: 1,
      add_dep: 1,
      remove_comments: 0,
      remove_comments: 1
    ]
  ]
]
