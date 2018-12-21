# Change Log

## [v0.6.1](https://github.com/infinitered/elasticsearch-elixir/tree/v0.6.1) (2018-12-21)
[Full Changelog](https://github.com/infinitered/elasticsearch-elixir/compare/v0.6.0...v0.6.1)

**Closed issues:**

- Document mapping type name can't start with '\_' [\#52](https://github.com/infinitered/elasticsearch-elixir/issues/52)
- Settings should maybe look in the current application's directory [\#51](https://github.com/infinitered/elasticsearch-elixir/issues/51)

**Merged pull requests:**

- Fix :default\_options config name [\#55](https://github.com/infinitered/elasticsearch-elixir/pull/55) ([nitinstp23](https://github.com/nitinstp23))
- Test against Elasticsearch 6.5.2 [\#53](https://github.com/infinitered/elasticsearch-elixir/pull/53) ([danielberkompas](https://github.com/danielberkompas))
- small typo fix: bang the spec [\#50](https://github.com/infinitered/elasticsearch-elixir/pull/50) ([alexfilatov](https://github.com/alexfilatov))

## [v0.6.0](https://github.com/infinitered/elasticsearch-elixir/tree/v0.6.0) (2018-10-19)
[Full Changelog](https://github.com/infinitered/elasticsearch-elixir/compare/v0.5.4...v0.6.0)

**Merged pull requests:**

- Delete the right index [\#49](https://github.com/infinitered/elasticsearch-elixir/pull/49) ([jfrolich](https://github.com/jfrolich))
- convert index alias to microseconds [\#48](https://github.com/infinitered/elasticsearch-elixir/pull/48) ([jfrolich](https://github.com/jfrolich))

## [v0.5.4](https://github.com/infinitered/elasticsearch-elixir/tree/v0.5.4) (2018-10-03)
[Full Changelog](https://github.com/infinitered/elasticsearch-elixir/compare/v0.5.3...v0.5.4)

**Closed issues:**

- Error installing on ubuntu linux [\#46](https://github.com/infinitered/elasticsearch-elixir/issues/46)

**Merged pull requests:**

- adds case statement to kibana download [\#47](https://github.com/infinitered/elasticsearch-elixir/pull/47) ([g13ydson](https://github.com/g13ydson))

## [v0.5.3](https://github.com/infinitered/elasticsearch-elixir/tree/v0.5.3) (2018-10-01)
[Full Changelog](https://github.com/infinitered/elasticsearch-elixir/compare/v0.5.2...v0.5.3)

**Merged pull requests:**

- fix: use correct typespec for response type [\#45](https://github.com/infinitered/elasticsearch-elixir/pull/45) ([sambou](https://github.com/sambou))

## [v0.5.2](https://github.com/infinitered/elasticsearch-elixir/tree/v0.5.2) (2018-09-19)
[Full Changelog](https://github.com/infinitered/elasticsearch-elixir/compare/v0.5.1...v0.5.2)

**Closed issues:**

- Error with the elasticsearch.build task [\#43](https://github.com/infinitered/elasticsearch-elixir/issues/43)

**Merged pull requests:**

- \[\#43\] Stop sending empty JSON payloads [\#44](https://github.com/infinitered/elasticsearch-elixir/pull/44) ([danielberkompas](https://github.com/danielberkompas))

## [v0.5.1](https://github.com/infinitered/elasticsearch-elixir/tree/v0.5.1) (2018-09-08)
[Full Changelog](https://github.com/infinitered/elasticsearch-elixir/compare/v0.5.0...v0.5.1)

**Closed issues:**

- Error when call build task with distillery [\#40](https://github.com/infinitered/elasticsearch-elixir/issues/40)
- FunctionClauseError: No function clause matching [\#39](https://github.com/infinitered/elasticsearch-elixir/issues/39)

## [v0.5.0](https://github.com/infinitered/elasticsearch-elixir/tree/v0.5.0) (2018-09-02)
[Full Changelog](https://github.com/infinitered/elasticsearch-elixir/compare/v0.4.1...v0.5.0)

**Closed issues:**

- Issue with dialyzer. [\#35](https://github.com/infinitered/elasticsearch-elixir/issues/35)
- Elasticsearch.StreamingStore behaviour or something alike [\#31](https://github.com/infinitered/elasticsearch-elixir/issues/31)

**Merged pull requests:**

- \[\#40\] Support Distillery [\#41](https://github.com/infinitered/elasticsearch-elixir/pull/41) ([danielberkompas](https://github.com/danielberkompas))
- Support \_routing meta-field [\#37](https://github.com/infinitered/elasticsearch-elixir/pull/37) ([cdunn](https://github.com/cdunn))
- \[\#31\] Base Store behaviour on streams [\#36](https://github.com/infinitered/elasticsearch-elixir/pull/36) ([danielberkompas](https://github.com/danielberkompas))

## [v0.4.1](https://github.com/infinitered/elasticsearch-elixir/tree/v0.4.1) (2018-06-26)
[Full Changelog](https://github.com/infinitered/elasticsearch-elixir/compare/v0.4.0...v0.4.1)

**Closed issues:**

- Handle Get API document not found error [\#33](https://github.com/infinitered/elasticsearch-elixir/issues/33)
- Compilation error in file lib/mix/elasticsearch.build.ex [\#30](https://github.com/infinitered/elasticsearch-elixir/issues/30)
- Deleting twice a document raises exception. [\#28](https://github.com/infinitered/elasticsearch-elixir/issues/28)

**Merged pull requests:**

- Support document-not-found error via Get API [\#34](https://github.com/infinitered/elasticsearch-elixir/pull/34) ([nitinstp23](https://github.com/nitinstp23))
- \[\#28\] Support not\_found response in Exception [\#32](https://github.com/infinitered/elasticsearch-elixir/pull/32) ([danielberkompas](https://github.com/danielberkompas))
- Add breaking change upgrade to documentation [\#29](https://github.com/infinitered/elasticsearch-elixir/pull/29) ([rhnonose](https://github.com/rhnonose))

## [v0.4.0](https://github.com/infinitered/elasticsearch-elixir/tree/v0.4.0) (2018-04-27)
[Full Changelog](https://github.com/infinitered/elasticsearch-elixir/compare/v0.3.1...v0.4.0)

**Closed issues:**

- Allow bulk configs to be overridable via mix tasks [\#26](https://github.com/infinitered/elasticsearch-elixir/issues/26)
- Make the mix task runnable through iex [\#25](https://github.com/infinitered/elasticsearch-elixir/issues/25)

**Merged pull requests:**

- \[\#26\] Configure bulk settings on indexes [\#27](https://github.com/infinitered/elasticsearch-elixir/pull/27) ([danielberkompas](https://github.com/danielberkompas))

## [v0.3.1](https://github.com/infinitered/elasticsearch-elixir/tree/v0.3.1) (2018-04-24)
[Full Changelog](https://github.com/infinitered/elasticsearch-elixir/compare/v0.3.0...v0.3.1)

**Closed issues:**

- Using elasticsearch as an executable gives error [\#23](https://github.com/infinitered/elasticsearch-elixir/issues/23)

**Merged pull requests:**

- Add `priv` dir when packaging application [\#24](https://github.com/infinitered/elasticsearch-elixir/pull/24) ([rhnonose](https://github.com/rhnonose))
- Fix executable example in README.md [\#22](https://github.com/infinitered/elasticsearch-elixir/pull/22) ([rhnonose](https://github.com/rhnonose))
- Add missing step to README [\#21](https://github.com/infinitered/elasticsearch-elixir/pull/21) ([xfumihiro](https://github.com/xfumihiro))

## [v0.3.0](https://github.com/infinitered/elasticsearch-elixir/tree/v0.3.0) (2018-04-19)
[Full Changelog](https://github.com/infinitered/elasticsearch-elixir/compare/v0.2.0...v0.3.0)

**Implemented enhancements:**

- Use Repo pattern for configuration [\#9](https://github.com/infinitered/elasticsearch-elixir/issues/9)
- bulk\_wait\_interval is unused [\#7](https://github.com/infinitered/elasticsearch-elixir/issues/7)

**Closed issues:**

- Support Elasticsearch 6.x+ [\#16](https://github.com/infinitered/elasticsearch-elixir/issues/16)
- Indexing fails on second Elasticsearch.Store load? [\#10](https://github.com/infinitered/elasticsearch-elixir/issues/10)
- Increase test coverage to \>90% [\#3](https://github.com/infinitered/elasticsearch-elixir/issues/3)

**Merged pull requests:**

- Support Elasticsearch 6.x [\#19](https://github.com/infinitered/elasticsearch-elixir/pull/19) ([danielberkompas](https://github.com/danielberkompas))

## [v0.2.0](https://github.com/infinitered/elasticsearch-elixir/tree/v0.2.0) (2018-04-18)
[Full Changelog](https://github.com/infinitered/elasticsearch-elixir/compare/v0.1.1...v0.2.0)

**Closed issues:**

- elasticsearch deprecated type=string  [\#14](https://github.com/infinitered/elasticsearch-elixir/issues/14)
- Documentation references execute/1 which doesn't seem to exist [\#11](https://github.com/infinitered/elasticsearch-elixir/issues/11)

**Merged pull requests:**

- Version 0.2 [\#15](https://github.com/infinitered/elasticsearch-elixir/pull/15) ([danielberkompas](https://github.com/danielberkompas))
- correct index source in README [\#12](https://github.com/infinitered/elasticsearch-elixir/pull/12) ([steffkes](https://github.com/steffkes))

## [v0.1.1](https://github.com/infinitered/elasticsearch-elixir/tree/v0.1.1) (2018-03-03)
[Full Changelog](https://github.com/infinitered/elasticsearch-elixir/compare/v0.1.0...v0.1.1)

**Closed issues:**

- SSL Errors with HTTPoison [\#5](https://github.com/infinitered/elasticsearch-elixir/issues/5)

**Merged pull requests:**

- \[\#5\] Allow configuring ':default\_options' [\#6](https://github.com/infinitered/elasticsearch-elixir/pull/6) ([danielberkompas](https://github.com/danielberkompas))

## [v0.1.0](https://github.com/infinitered/elasticsearch-elixir/tree/v0.1.0) (2018-01-02)
**Merged pull requests:**

- Code coverage with Coveralls [\#2](https://github.com/infinitered/elasticsearch-elixir/pull/2) ([danielberkompas](https://github.com/danielberkompas))
- Rework configuration [\#1](https://github.com/infinitered/elasticsearch-elixir/pull/1) ([danielberkompas](https://github.com/danielberkompas))



\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*