Delta     = require('rich-text/lib/delta')
Parchment = require('parchment')
extend    = require('extend')


NEWLINE_LENGTH = 1


class Block extends Parchment.Block
  @blotName = 'block'
  @tagName = 'P'

  build: ->
    super()
    this.ensureChild()

  deleteAt: (index, length) ->
    super(index, length)
    this.ensureChild()

  ensureChild: ->
    if this.children.length == 0
      this.appendChild(Parchment.create('break'))

  findPath: (index) ->
    return super(index, true)

  format: (name, value) ->
    blot = Parchment.match(name, Parchment.Type.BLOT)
    if blot? && blot.prototype instanceof Parchment.Block ||
       blot.prototype instanceof Parchment.Container ||
       Parchment.match(name, Parchment.Type.ATTRIBUTE)
      super(name, value)

  formatAt: (index, length, name, value) ->
    if index + length >= this.getLength() and length > 0
      this.format(name, value)
    super(index, length, name, value)

  getDelta: ->
    leaves = this.getDescendants(Parchment.Leaf)
    return leaves.reduceRight((delta, leaf) =>
      return delta if leaf.getLength() == 0
      attributes = {}
      value = leaf.getValue()
      while (leaf != this)
        attributes = extend({}, leaf.getFormat(), attributes)
        leaf = leaf.parent
      return new Delta().insert(value, attributes).concat(delta)
    , new Delta().insert('\n', this.getFormat()))

  getLength: ->
    return super() + NEWLINE_LENGTH

  getValue: ->
    return super().concat(['\n'])

  insertAt: (index, value, def) ->
    return super(index, value, def) if def?
    return if value.length == 0
    lines = value.split('\n')
    text = lines.shift()
    super(index, text)
    if lines.length > 0
      next = this.split(index + text.length, true)
      next.insertAt(0, lines.join('\n'))

  insertBefore: (blot, ref) ->
    if @children.head? && @children.head.statics.blotName == 'break'
      br = @children.head
    super(blot, ref)
    br.remove() if br?

  split: (index, force = false) ->
    if force && (index == 0 || index >= this.getLength() - NEWLINE_LENGTH)
      after = this.clone()
      if index == 0
        this.moveChildren(after)
        this.ensureChild()
      else
        after.ensureChild()
      @parent.insertBefore(after, @next)
      return after
    return super(index, force)


Parchment.register(Block)

module.exports = Block
